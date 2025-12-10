import Foundation
import SwiftData

/// A logged activity that was interpreted by the AI and awarded skill XP
@Model
class Activity {
    var id: UUID
    var timestamp: Date

    // User input
    var rawInput: String         // What the user typed
    var source: ActivitySource   // How it was logged

    // AI interpretation
    var interpretation: String?  // AI's understanding of the activity
    var skillGains: [SkillGain]  // Skills and XP awarded
    var aiNotes: String?         // Additional AI observations

    // Context at time of logging
    var healthAtTime: Int?
    var energyAtTime: Int?
    var moodRating: Int?         // 1-5 optional mood

    // Relationships
    var character: Character?
    var completedQuestID: UUID?  // If this completed a quest

    // HealthKit data (if auto-logged)
    var healthKitType: String?   // e.g., "HKWorkoutActivityTypeRunning"
    var healthKitValue: Double?  // e.g., 5.2 (km)
    var healthKitUnit: String?   // e.g., "km"
    var healthKitDuration: TimeInterval?

    init(rawInput: String, source: ActivitySource = .manual) {
        self.id = UUID()
        self.timestamp = Date()
        self.rawInput = rawInput
        self.source = source
        self.interpretation = nil
        self.skillGains = []
        self.aiNotes = nil
        self.healthAtTime = nil
        self.energyAtTime = nil
        self.moodRating = nil
        self.completedQuestID = nil
        self.healthKitType = nil
        self.healthKitValue = nil
        self.healthKitUnit = nil
        self.healthKitDuration = nil
    }

    // MARK: - Convenience Initializers

    static func fromHealthKit(
        type: String,
        value: Double,
        unit: String,
        duration: TimeInterval?,
        description: String
    ) -> Activity {
        let activity = Activity(rawInput: description, source: .healthKit)
        activity.healthKitType = type
        activity.healthKitValue = value
        activity.healthKitUnit = unit
        activity.healthKitDuration = duration
        return activity
    }

    static func fromQuestCompletion(quest: Quest) -> Activity {
        let activity = Activity(
            rawInput: "Completed: \(quest.name)",
            source: .questComplete
        )
        activity.completedQuestID = quest.id
        activity.skillGains = quest.skillGains
        activity.interpretation = quest.questDescription
        return activity
    }

    // MARK: - Computed Properties

    var totalXPAwarded: Int {
        skillGains.reduce(0) { $0 + $1.amount }
    }

    var skillsTrainedCount: Int {
        skillGains.count
    }

    var formattedDuration: String? {
        guard let duration = healthKitDuration else { return nil }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    var displayDescription: String {
        interpretation ?? rawInput
    }
}

// MARK: - Activity Source

enum ActivitySource: String, Codable {
    case manual = "Manual"          // User typed it
    case healthKit = "HealthKit"    // Auto-imported
    case questComplete = "Quest"    // From completing a quest
    case aiSuggested = "AI"         // AI suggested, user confirmed

    var icon: String {
        switch self {
        case .manual: return "pencil"
        case .healthKit: return "heart.fill"
        case .questComplete: return "checkmark.circle.fill"
        case .aiSuggested: return "sparkles"
        }
    }
}

// MARK: - Activity Summary

extension Activity {
    struct DailySummary {
        let date: Date
        let activities: [Activity]
        let totalXP: Int
        let skillsGained: [String: Int]  // skillID -> total XP

        var activityCount: Int { activities.count }

        init(date: Date, activities: [Activity]) {
            self.date = date
            self.activities = activities
            self.totalXP = activities.reduce(0) { $0 + $1.totalXPAwarded }

            var skills: [String: Int] = [:]
            for activity in activities {
                for gain in activity.skillGains {
                    skills[gain.skillID, default: 0] += gain.amount
                }
            }
            self.skillsGained = skills
        }
    }

    static func groupByDay(_ activities: [Activity]) -> [DailySummary] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: activities) { activity in
            calendar.startOfDay(for: activity.timestamp)
        }

        return grouped.map { DailySummary(date: $0.key, activities: $0.value) }
            .sorted { $0.date > $1.date }
    }
}
