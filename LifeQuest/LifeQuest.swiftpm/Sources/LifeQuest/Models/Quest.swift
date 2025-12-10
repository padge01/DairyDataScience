import Foundation
import SwiftData

/// A task or routine that awards XP when completed
@Model
class Quest {
    var id: UUID
    var name: String
    var questDescription: String
    var questType: QuestType
    var isActive: Bool

    // Rewards
    var baseXP: Int
    var skillGains: [SkillGain]

    // Completion tracking
    var isCompletedToday: Bool
    var completedCount: Int
    var lastCompletedAt: Date?

    // For weekly quests
    var targetCount: Int        // How many times per period
    var currentPeriodCount: Int // Progress this period

    // Streaks
    var currentStreak: Int
    var longestStreak: Int
    var lastStreakDate: Date?

    // Auto-completion
    var autoCompleteType: AutoCompleteType?
    var autoCompleteThreshold: Double?  // e.g., 10000 steps

    // Scheduling
    var scheduledDays: [Int]?  // 1-7 for specific days, nil for every day
    var reminderTime: Date?

    // Relationship
    var character: Character?

    init(
        name: String,
        description: String,
        type: QuestType,
        baseXP: Int,
        skillGains: [SkillGain] = []
    ) {
        self.id = UUID()
        self.name = name
        self.questDescription = description
        self.questType = type
        self.isActive = true
        self.baseXP = baseXP
        self.skillGains = skillGains
        self.isCompletedToday = false
        self.completedCount = 0
        self.lastCompletedAt = nil
        self.targetCount = 1
        self.currentPeriodCount = 0
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastStreakDate = nil
        self.autoCompleteType = nil
        self.autoCompleteThreshold = nil
        self.scheduledDays = nil
        self.reminderTime = nil
    }

    // MARK: - Streak Calculations

    var streakMultiplier: Double {
        switch currentStreak {
        case 0...3: return 1.0
        case 4...7: return 1.25
        case 8...14: return 1.5
        case 15...30: return 1.75
        case 31...60: return 2.0
        case 61...90: return 2.25
        default: return 2.5
        }
    }

    var effectiveXP: Int {
        Int(Double(baseXP) * streakMultiplier)
    }

    var streakTier: StreakTier {
        switch currentStreak {
        case 0...3: return .starting
        case 4...7: return .building
        case 8...14: return .consistent
        case 15...30: return .dedicated
        case 31...60: return .habitFormed
        case 61...90: return .lifestyle
        default: return .mastery
        }
    }

    // MARK: - Completion

    func complete() {
        let now = Date()
        isCompletedToday = true
        completedCount += 1
        currentPeriodCount += 1
        lastCompletedAt = now

        updateStreak(completedAt: now)
    }

    func resetDaily() {
        isCompletedToday = false
    }

    func resetWeekly() {
        currentPeriodCount = 0
    }

    private func updateStreak(completedAt: Date) {
        guard let lastDate = lastStreakDate else {
            currentStreak = 1
            lastStreakDate = completedAt
            longestStreak = max(longestStreak, 1)
            return
        }

        let calendar = Calendar.current
        let daysSinceLast = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastDate),
            to: calendar.startOfDay(for: completedAt)
        ).day ?? 0

        switch daysSinceLast {
        case 0:
            // Same day, no change
            break
        case 1:
            // Consecutive day
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
            lastStreakDate = completedAt
        default:
            // Streak broken (allow 1 grace day in future version)
            currentStreak = 1
            lastStreakDate = completedAt
        }
    }

    // MARK: - Scheduling

    func isScheduledForToday() -> Bool {
        guard let days = scheduledDays, !days.isEmpty else {
            return true // No specific days = every day
        }
        let weekday = Calendar.current.component(.weekday, from: Date())
        return days.contains(weekday)
    }
}

// MARK: - Quest Types

enum QuestType: String, Codable, CaseIterable {
    case daily = "Daily"
    case weekly = "Weekly"
    case oneTime = "One-Time"

    var icon: String {
        switch self {
        case .daily: return "sun.max"
        case .weekly: return "calendar"
        case .oneTime: return "star"
        }
    }
}

// MARK: - Streak Tiers

enum StreakTier: String {
    case starting = "Starting"
    case building = "Building"
    case consistent = "Consistent"
    case dedicated = "Dedicated"
    case habitFormed = "Habit Formed"
    case lifestyle = "Lifestyle"
    case mastery = "Mastery"

    var color: String {
        switch self {
        case .starting: return "gray"
        case .building: return "blue"
        case .consistent: return "green"
        case .dedicated: return "yellow"
        case .habitFormed: return "orange"
        case .lifestyle: return "red"
        case .mastery: return "purple"
        }
    }
}

// MARK: - Auto Complete Types

enum AutoCompleteType: String, Codable, CaseIterable {
    case steps = "Steps"
    case activeEnergy = "Active Energy"
    case workout = "Workout"
    case sleepHours = "Sleep Hours"
    case standHours = "Stand Hours"

    var healthKitIdentifier: String {
        switch self {
        case .steps: return "HKQuantityTypeIdentifierStepCount"
        case .activeEnergy: return "HKQuantityTypeIdentifierActiveEnergyBurned"
        case .workout: return "HKWorkoutTypeIdentifier"
        case .sleepHours: return "HKCategoryTypeIdentifierSleepAnalysis"
        case .standHours: return "HKCategoryTypeIdentifierAppleStandHour"
        }
    }
}

// MARK: - Skill Gain

struct SkillGain: Codable, Identifiable {
    var id: UUID
    var skillID: String
    var amount: Int
    var reason: String?

    init(skillID: String, amount: Int, reason: String? = nil) {
        self.id = UUID()
        self.skillID = skillID
        self.amount = amount
        self.reason = reason
    }
}

// MARK: - Default Quests

extension Quest {
    static func createDefaultQuests() -> [Quest] {
        [
            {
                let q = Quest(
                    name: "Daily Steps",
                    description: "Walk 10,000 steps",
                    type: .daily,
                    baseXP: 30,
                    skillGains: [SkillGain(skillID: "endurance", amount: 20)]
                )
                q.autoCompleteType = .steps
                q.autoCompleteThreshold = 10000
                return q
            }(),
            Quest(
                name: "Morning Movement",
                description: "10 minutes of intentional movement",
                type: .daily,
                baseXP: 20,
                skillGains: [
                    SkillGain(skillID: "mobility", amount: 10),
                    SkillGain(skillID: "endurance", amount: 5)
                ]
            ),
            Quest(
                name: "Deep Work Block",
                description: "90 minutes of focused, uninterrupted work",
                type: .daily,
                baseXP: 40,
                skillGains: [
                    SkillGain(skillID: "focus", amount: 25),
                    SkillGain(skillID: "problem_solving", amount: 10)
                ]
            ),
            {
                let q = Quest(
                    name: "Quality Sleep",
                    description: "Get 7+ hours of sleep",
                    type: .daily,
                    baseXP: 25,
                    skillGains: [
                        SkillGain(skillID: "sleep", amount: 20),
                        SkillGain(skillID: "recovery", amount: 15)
                    ]
                )
                q.autoCompleteType = .sleepHours
                q.autoCompleteThreshold = 7.0
                return q
            }(),
            Quest(
                name: "Train 3x",
                description: "Complete 3 workout sessions this week",
                type: .weekly,
                baseXP: 100,
                skillGains: [
                    SkillGain(skillID: "strength", amount: 30),
                    SkillGain(skillID: "endurance", amount: 30)
                ]
            ),
            Quest(
                name: "Learn Something",
                description: "Spend 2+ hours learning this week",
                type: .weekly,
                baseXP: 75,
                skillGains: [SkillGain(skillID: "learning", amount: 40)]
            ),
        ]
    }
}
