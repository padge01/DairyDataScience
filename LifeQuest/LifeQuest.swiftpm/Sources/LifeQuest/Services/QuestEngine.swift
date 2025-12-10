import Foundation
import SwiftData

/// Manages quest scheduling, completion, and auto-completion via HealthKit
@Observable
class QuestEngine {
    private var modelContext: ModelContext
    private var healthKitService: HealthKitService
    private var progressionEngine: ProgressionEngine

    var todaysQuests: [Quest] = []
    var weeklyQuests: [Quest] = []

    init(
        modelContext: ModelContext,
        healthKitService: HealthKitService,
        progressionEngine: ProgressionEngine
    ) {
        self.modelContext = modelContext
        self.healthKitService = healthKitService
        self.progressionEngine = progressionEngine
    }

    // MARK: - Quest Loading

    /// Load today's active quests for a character
    func loadTodaysQuests(for character: Character) {
        let allQuests = character.quests

        // Filter daily quests scheduled for today
        todaysQuests = allQuests.filter { quest in
            quest.questType == .daily &&
            quest.isActive &&
            quest.isScheduledForToday()
        }

        // Load weekly quests
        weeklyQuests = allQuests.filter { quest in
            quest.questType == .weekly && quest.isActive
        }
    }

    // MARK: - Quest Completion

    /// Complete a quest and award XP
    func completeQuest(
        _ quest: Quest,
        for character: Character
    ) -> QuestCompletionResult {
        guard !quest.isCompletedToday || quest.questType == .weekly else {
            return QuestCompletionResult(success: false, error: "Quest already completed today")
        }

        // Mark complete
        quest.complete()

        // Create activity record
        let activity = Activity.fromQuestCompletion(quest: quest)
        activity.character = character
        character.activities.append(activity)

        // Award XP for each skill
        let results = progressionEngine.processSkillGains(
            character: character,
            gains: quest.skillGains,
            streakDays: quest.currentStreak
        )

        // Calculate total XP with streak multiplier
        let totalXP = results.reduce(0) { $0 + $1.xpAwarded }

        // Collect level ups
        let skillLevelUps = results.flatMap { $0.skillLevelUps }
        let characterLevelUp = results.compactMap { $0.characterLevelUp }.first

        return QuestCompletionResult(
            success: true,
            xpAwarded: totalXP,
            streakMultiplier: quest.streakMultiplier,
            newStreak: quest.currentStreak,
            skillLevelUps: skillLevelUps,
            characterLevelUp: characterLevelUp
        )
    }

    // MARK: - Auto-Completion

    /// Check HealthKit data and auto-complete eligible quests
    func checkAutoCompletions(for character: Character) async -> [QuestCompletionResult] {
        var results: [QuestCompletionResult] = []

        for quest in todaysQuests where !quest.isCompletedToday {
            guard let autoType = quest.autoCompleteType,
                  let threshold = quest.autoCompleteThreshold else {
                continue
            }

            let currentValue = await fetchHealthKitValue(for: autoType)

            if currentValue >= threshold {
                let result = completeQuest(quest, for: character)
                results.append(result)
            }
        }

        return results
    }

    private func fetchHealthKitValue(for type: AutoCompleteType) async -> Double {
        switch type {
        case .steps:
            return Double(await healthKitService.fetchTodaySteps())
        case .activeEnergy:
            return await healthKitService.fetchTodayActiveEnergy()
        case .sleepHours:
            let sleep = await healthKitService.fetchLastNightSleep()
            return sleep?.hoursAsleep ?? 0
        case .workout:
            let workouts = await healthKitService.fetchRecentWorkouts(days: 1)
            return workouts.isEmpty ? 0 : 1
        case .standHours:
            // Would need additional HealthKit query
            return 0
        }
    }

    // MARK: - Daily/Weekly Reset

    /// Reset daily quests at the configured reset time
    func performDailyReset(for character: Character) {
        for quest in character.quests where quest.questType == .daily {
            // Check if streak should break
            if let lastComplete = quest.lastCompletedAt {
                let calendar = Calendar.current
                let daysSinceLast = calendar.dateComponents(
                    [.day],
                    from: calendar.startOfDay(for: lastComplete),
                    to: calendar.startOfDay(for: Date())
                ).day ?? 0

                if daysSinceLast > 1 {
                    // Streak broken (missed a day)
                    quest.currentStreak = 0
                }
            }

            quest.resetDaily()
        }
    }

    /// Reset weekly quests on the configured day
    func performWeeklyReset(for character: Character) {
        for quest in character.quests where quest.questType == .weekly {
            // Check if target was met
            if quest.currentPeriodCount < quest.targetCount {
                quest.currentStreak = 0
            }
            quest.resetWeekly()
        }
    }

    // MARK: - Quest Management

    /// Create a new quest for a character
    func createQuest(
        for character: Character,
        name: String,
        description: String,
        type: QuestType,
        baseXP: Int,
        skillGains: [SkillGain],
        autoComplete: AutoCompleteType? = nil,
        threshold: Double? = nil,
        scheduledDays: [Int]? = nil
    ) -> Quest {
        let quest = Quest(
            name: name,
            description: description,
            type: type,
            baseXP: baseXP,
            skillGains: skillGains
        )

        quest.autoCompleteType = autoComplete
        quest.autoCompleteThreshold = threshold
        quest.scheduledDays = scheduledDays
        quest.character = character

        character.quests.append(quest)

        return quest
    }

    /// Archive (deactivate) a quest
    func archiveQuest(_ quest: Quest) {
        quest.isActive = false
    }

    /// Delete a quest permanently
    func deleteQuest(_ quest: Quest, from character: Character) {
        if let index = character.quests.firstIndex(where: { $0.id == quest.id }) {
            character.quests.remove(at: index)
        }
        modelContext.delete(quest)
    }

    // MARK: - Quest Suggestions

    /// Get suggested quests based on character's weak skills
    func suggestedQuests(for character: Character) -> [QuestSuggestion] {
        var suggestions: [QuestSuggestion] = []

        // Find lowest level skills
        let sortedSkills = character.skills.sorted { $0.currentLevel < $1.currentLevel }
        let weakSkills = sortedSkills.prefix(3)

        for skill in weakSkills {
            suggestions.append(contentsOf: suggestionsForSkill(skill))
        }

        return suggestions
    }

    private func suggestionsForSkill(_ skill: Skill) -> [QuestSuggestion] {
        switch skill.skillID {
        case "endurance":
            return [
                QuestSuggestion(
                    name: "Daily Walk",
                    description: "Take a 20-minute walk",
                    skillID: "endurance",
                    estimatedXP: 15,
                    difficulty: .easy
                )
            ]
        case "strength":
            return [
                QuestSuggestion(
                    name: "Bodyweight Basics",
                    description: "10 pushups, 10 squats, 10 lunges",
                    skillID: "strength",
                    estimatedXP: 20,
                    difficulty: .medium
                )
            ]
        case "focus":
            return [
                QuestSuggestion(
                    name: "Pomodoro Session",
                    description: "25 minutes of focused work",
                    skillID: "focus",
                    estimatedXP: 25,
                    difficulty: .medium
                )
            ]
        case "sleep":
            return [
                QuestSuggestion(
                    name: "Wind Down",
                    description: "No screens 30 min before bed",
                    skillID: "sleep",
                    estimatedXP: 15,
                    difficulty: .easy
                )
            ]
        default:
            return []
        }
    }
}

// MARK: - Result Types

struct QuestCompletionResult {
    var success: Bool
    var error: String?
    var xpAwarded: Int = 0
    var streakMultiplier: Double = 1.0
    var newStreak: Int = 0
    var skillLevelUps: [LevelUp] = []
    var characterLevelUp: CharacterLevelUp?
}

struct QuestSuggestion: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let skillID: String
    let estimatedXP: Int
    let difficulty: QuestDifficulty
}

enum QuestDifficulty: String {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"

    var color: String {
        switch self {
        case .easy: return "green"
        case .medium: return "yellow"
        case .hard: return "red"
        }
    }
}
