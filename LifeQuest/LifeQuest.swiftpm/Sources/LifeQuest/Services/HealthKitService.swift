import Foundation
import HealthKit

/// Handles all HealthKit integration for auto-tracking activities
@Observable
class HealthKitService {
    private let healthStore = HKHealthStore()

    var isAuthorized = false
    var authorizationError: String?

    // Cached data
    var todaySteps: Int = 0
    var todaySleepHours: Double = 0
    var todayActiveEnergy: Double = 0
    var recentWorkouts: [WorkoutSummary] = []

    // MARK: - Authorization

    /// Request HealthKit permissions
    func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            authorizationError = "HealthKit not available on this device"
            return false
        }

        // Types we want to read
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceWalkingRunning),
            HKQuantityType(.heartRate),
            HKQuantityType(.heartRateVariabilitySDNN),
            HKCategoryType(.sleepAnalysis),
            HKObjectType.workoutType()
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            isAuthorized = true
            return true
        } catch {
            authorizationError = error.localizedDescription
            return false
        }
    }

    // MARK: - Step Count

    /// Fetch today's step count
    func fetchTodaySteps() async -> Int {
        let stepType = HKQuantityType(.stepCount)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        do {
            let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: stepType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, statistics, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let statistics = statistics {
                        continuation.resume(returning: statistics)
                    } else {
                        continuation.resume(throwing: HealthKitError.noData)
                    }
                }
                healthStore.execute(query)
            }

            let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
            todaySteps = Int(steps)
            return Int(steps)
        } catch {
            return 0
        }
    }

    // MARK: - Sleep Analysis

    /// Fetch last night's sleep data
    func fetchLastNightSleep() async -> SleepData? {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let predicate = HKQuery.predicateForSamples(
            withStart: yesterday,
            end: now,
            options: .strictStartDate
        )

        do {
            let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
                let query = HKSampleQuery(
                    sampleType: sleepType,
                    predicate: predicate,
                    limit: HKObjectQueryNoLimit,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: samples as? [HKCategorySample] ?? [])
                    }
                }
                healthStore.execute(query)
            }

            // Calculate total sleep time
            var totalAsleep: TimeInterval = 0
            var totalInBed: TimeInterval = 0

            for sample in samples {
                let duration = sample.endDate.timeIntervalSince(sample.startDate)
                if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                   sample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue {
                    totalAsleep += duration
                }
                totalInBed += duration
            }

            let hoursAsleep = totalAsleep / 3600
            todaySleepHours = hoursAsleep

            return SleepData(
                hoursAsleep: hoursAsleep,
                hoursInBed: totalInBed / 3600,
                quality: determineSleepQuality(hoursAsleep: hoursAsleep)
            )
        } catch {
            return nil
        }
    }

    private func determineSleepQuality(hoursAsleep: Double) -> SleepQuality {
        switch hoursAsleep {
        case ..<5: return .poor
        case 5..<7: return .normal
        case 7..<8: return .good
        default: return .excellent
        }
    }

    // MARK: - Workouts

    /// Fetch recent workouts
    func fetchRecentWorkouts(days: Int = 7) async -> [WorkoutSummary] {
        let now = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: now)!
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: now,
            options: .strictStartDate
        )

        do {
            let workouts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
                let query = HKSampleQuery(
                    sampleType: .workoutType(),
                    predicate: predicate,
                    limit: 50,
                    sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
                ) { _, samples, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: samples as? [HKWorkout] ?? [])
                    }
                }
                healthStore.execute(query)
            }

            recentWorkouts = workouts.map { workout in
                WorkoutSummary(
                    id: workout.uuid,
                    type: workout.workoutActivityType,
                    startDate: workout.startDate,
                    duration: workout.duration,
                    calories: workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                    distance: workout.totalDistance?.doubleValue(for: .meter()) ?? 0
                )
            }

            return recentWorkouts
        } catch {
            return []
        }
    }

    // MARK: - Active Energy

    /// Fetch today's active energy burned
    func fetchTodayActiveEnergy() async -> Double {
        let energyType = HKQuantityType(.activeEnergyBurned)
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )

        do {
            let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics, Error>) in
                let query = HKStatisticsQuery(
                    quantityType: energyType,
                    quantitySamplePredicate: predicate,
                    options: .cumulativeSum
                ) { _, statistics, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else if let statistics = statistics {
                        continuation.resume(returning: statistics)
                    } else {
                        continuation.resume(throwing: HealthKitError.noData)
                    }
                }
                healthStore.execute(query)
            }

            let energy = statistics.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
            todayActiveEnergy = energy
            return energy
        } catch {
            return 0
        }
    }

    // MARK: - Background Observation

    /// Set up background observers for real-time updates
    func enableBackgroundDelivery() async {
        let stepType = HKQuantityType(.stepCount)

        do {
            try await healthStore.enableBackgroundDelivery(
                for: stepType,
                frequency: .hourly
            )
        } catch {
            print("Failed to enable background delivery: \(error)")
        }
    }

    // MARK: - Workout to Skill Mapping

    /// Map a workout type to skill gains
    func skillGainsForWorkout(_ workout: WorkoutSummary) -> [SkillGain] {
        var gains: [SkillGain] = []

        let durationMinutes = workout.duration / 60
        let intensityMultiplier = min(2.0, durationMinutes / 30) // Scale up to 60min

        switch workout.type {
        case .traditionalStrengthTraining, .functionalStrengthTraining:
            gains.append(SkillGain(
                skillID: "strength",
                amount: Int(25 * intensityMultiplier),
                reason: "Strength training workout"
            ))
            gains.append(SkillGain(
                skillID: "endurance",
                amount: Int(10 * intensityMultiplier),
                reason: "Workout endurance"
            ))

        case .running, .cycling, .swimming:
            gains.append(SkillGain(
                skillID: "endurance",
                amount: Int(30 * intensityMultiplier),
                reason: "Cardio workout"
            ))

        case .yoga, .flexibility:
            gains.append(SkillGain(
                skillID: "mobility",
                amount: Int(25 * intensityMultiplier),
                reason: "Flexibility training"
            ))
            gains.append(SkillGain(
                skillID: "stress_management",
                amount: Int(15 * intensityMultiplier),
                reason: "Mind-body practice"
            ))

        case .martialArts, .boxing, .wrestling:
            gains.append(SkillGain(
                skillID: "endurance",
                amount: Int(25 * intensityMultiplier),
                reason: "Combat training"
            ))
            gains.append(SkillGain(
                skillID: "mobility",
                amount: Int(15 * intensityMultiplier),
                reason: "Combat mobility"
            ))
            gains.append(SkillGain(
                skillID: "focus",
                amount: Int(10 * intensityMultiplier),
                reason: "Combat focus"
            ))

        case .walking, .hiking:
            gains.append(SkillGain(
                skillID: "endurance",
                amount: Int(15 * intensityMultiplier),
                reason: "Walking activity"
            ))

        default:
            // Generic workout gains
            gains.append(SkillGain(
                skillID: "endurance",
                amount: Int(20 * intensityMultiplier),
                reason: "Physical activity"
            ))
        }

        return gains
    }
}

// MARK: - Supporting Types

struct SleepData {
    let hoursAsleep: Double
    let hoursInBed: Double
    let quality: SleepQuality
}

struct WorkoutSummary: Identifiable {
    let id: UUID
    let type: HKWorkoutActivityType
    let startDate: Date
    let duration: TimeInterval
    let calories: Double
    let distance: Double

    var durationFormatted: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var typeName: String {
        switch type {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .walking: return "Walking"
        case .hiking: return "Hiking"
        case .yoga: return "Yoga"
        case .traditionalStrengthTraining: return "Strength Training"
        case .functionalStrengthTraining: return "Functional Training"
        case .martialArts: return "Martial Arts"
        case .boxing: return "Boxing"
        case .wrestling: return "Wrestling"
        default: return "Workout"
        }
    }
}

enum HealthKitError: Error {
    case noData
    case notAuthorized
    case notAvailable
}
