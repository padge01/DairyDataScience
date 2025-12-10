import Foundation
import SwiftData

/// Main view model for character state and actions
@Observable
class CharacterViewModel {
    // MARK: - State
    var character: Character?
    var isLoading = false
    var error: String?

    // Level up celebration
    var showLevelUp = false
    var recentLevelUp: CharacterLevelUp?
    var recentSkillLevelUps: [LevelUp] = []

    // MARK: - Dependencies
    private var modelContext: ModelContext
    private var progressionEngine: ProgressionEngine
    private var questEngine: QuestEngine
    private var healthKitService: HealthKitService
    private var aiService: AIService
    private var memoryManager: MemoryManager

    init(
        modelContext: ModelContext,
        progressionEngine: ProgressionEngine,
        questEngine: QuestEngine,
        healthKitService: HealthKitService,
        aiService: AIService,
        memoryManager: MemoryManager
    ) {
        self.modelContext = modelContext
        self.progressionEngine = progressionEngine
        self.questEngine = questEngine
        self.healthKitService = healthKitService
        self.aiService = aiService
        self.memoryManager = memoryManager
    }

    // MARK: - Character Loading

    func loadCharacter() {
        isLoading = true
        defer { isLoading = false }

        let descriptor = FetchDescriptor<Character>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let characters = try modelContext.fetch(descriptor)
            character = characters.first
        } catch {
            self.error = error.localizedDescription
        }
    }

    func createCharacter(name: String, majorSkills: [String], minorSkills: [String]) {
        let newCharacter = Character(name: name)

        // Create all skills
        let skills = Skill.createDefaultSkills()
        for skill in skills {
            skill.character = newCharacter

            // Set starting levels based on major/minor designation
            if majorSkills.contains(skill.skillID) {
                skill.currentLevel = 10
                skill.totalXP = Skill.totalXPForLevel(10)
            } else if minorSkills.contains(skill.skillID) {
                skill.currentLevel = 5
                skill.totalXP = Skill.totalXPForLevel(5)
            }
        }

        newCharacter.skills = skills
        newCharacter.majorSkillIDs = majorSkills
        newCharacter.minorSkillIDs = minorSkills

        // Add default quests
        let defaultQuests = Quest.createDefaultQuests()
        for quest in defaultQuests {
            quest.character = newCharacter
        }
        newCharacter.quests = defaultQuests

        modelContext.insert(newCharacter)

        do {
            try modelContext.save()
            character = newCharacter
        } catch {
            self.error = error.localizedDescription
        }
    }

    // MARK: - Activity Logging

    func logActivity(_ input: String) async {
        guard let character = character else { return }

        isLoading = true
        defer { isLoading = false }

        // Create activity record
        let activity = Activity(rawInput: input, source: .manual)
        activity.healthAtTime = character.currentHealth
        activity.energyAtTime = character.currentEnergy
        activity.character = character

        // Get AI interpretation if available
        if aiService.isConfigured {
            let context = memoryManager.buildContext(for: character)

            if let interpretation = await aiService.interpretActivity(
                input,
                character: character,
                context: context
            ) {
                activity.interpretation = interpretation.interpretation
                activity.skillGains = interpretation.skillGains
                activity.aiNotes = interpretation.notes

                // Apply energy/health costs
                if interpretation.energyCost > 0 {
                    progressionEngine.consumeEnergy(
                        character: character,
                        amount: interpretation.energyCost
                    )
                }
                if interpretation.healthCost > 0 {
                    progressionEngine.consumeHealth(
                        character: character,
                        amount: interpretation.healthCost
                    )
                }
            }
        } else {
            // Fallback: simple skill matching
            activity.skillGains = simpleSkillMatch(input)
            activity.interpretation = input
        }

        // Award XP
        let results = progressionEngine.processSkillGains(
            character: character,
            gains: activity.skillGains
        )

        // Check for level ups
        recentSkillLevelUps = results.flatMap { $0.skillLevelUps }
        if let charLevelUp = results.compactMap({ $0.characterLevelUp }).first {
            recentLevelUp = charLevelUp
            showLevelUp = true
        }

        // Save activity
        character.activities.append(activity)

        // Record memory
        memoryManager.recordActivity(activity, for: character)

        try? modelContext.save()
    }

    private func simpleSkillMatch(_ input: String) -> [SkillGain] {
        let lower = input.lowercased()
        var gains: [SkillGain] = []

        // Simple keyword matching
        if lower.contains("workout") || lower.contains("gym") || lower.contains("lift") {
            gains.append(SkillGain(skillID: "strength", amount: 25))
        }
        if lower.contains("run") || lower.contains("walk") || lower.contains("cardio") {
            gains.append(SkillGain(skillID: "endurance", amount: 20))
        }
        if lower.contains("read") || lower.contains("study") || lower.contains("learn") {
            gains.append(SkillGain(skillID: "learning", amount: 20))
        }
        if lower.contains("code") || lower.contains("program") || lower.contains("work") {
            gains.append(SkillGain(skillID: "focus", amount: 15))
            gains.append(SkillGain(skillID: "problem_solving", amount: 15))
        }
        if lower.contains("meditat") || lower.contains("yoga") || lower.contains("stretch") {
            gains.append(SkillGain(skillID: "stress_management", amount: 20))
            gains.append(SkillGain(skillID: "mobility", amount: 15))
        }

        // Default if no matches
        if gains.isEmpty {
            gains.append(SkillGain(skillID: "focus", amount: 10))
        }

        return gains
    }

    // MARK: - Quest Completion

    func completeQuest(_ quest: Quest) {
        guard let character = character else { return }

        let result = questEngine.completeQuest(quest, for: character)

        if result.success {
            recentSkillLevelUps = result.skillLevelUps
            if let charLevelUp = result.characterLevelUp {
                recentLevelUp = charLevelUp
                showLevelUp = true
            }
        }

        try? modelContext.save()
    }

    // MARK: - Health Sync

    func syncHealthData() async {
        guard let character = character else { return }

        // Request authorization if needed
        if !healthKitService.isAuthorized {
            _ = await healthKitService.requestAuthorization()
        }

        // Fetch and process sleep
        if let sleep = await healthKitService.fetchLastNightSleep() {
            progressionEngine.processRecovery(
                character: character,
                sleepHours: sleep.hoursAsleep,
                sleepQuality: sleep.quality
            )
        }

        // Check auto-completions
        questEngine.loadTodaysQuests(for: character)
        let completions = await questEngine.checkAutoCompletions(for: character)

        // Collect level ups from auto-completions
        recentSkillLevelUps = completions.flatMap { $0.skillLevelUps }

        try? modelContext.save()
    }

    // MARK: - Daily Reset

    func performDailyReset() {
        guard let character = character else { return }

        questEngine.performDailyReset(for: character)
        try? modelContext.save()
    }

    // MARK: - Computed Properties

    var healthPercentage: Double {
        character?.healthPercentage ?? 0
    }

    var energyPercentage: Double {
        character?.energyPercentage ?? 0
    }

    var xpProgress: Double {
        guard let char = character else { return 0 }
        guard char.xpToNextLevel > 0 else { return 1 }
        let currentLevelXP = char.totalXP - xpForLevel(char.level)
        return Double(currentLevelXP) / Double(char.xpToNextLevel)
    }

    private func xpForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        return Int(pow(Double(level - 1), 1.5) * 100) * Constants.Progression.skillLevelsPerCharacterLevel
    }

    var topSkills: [Skill] {
        character?.skills
            .sorted { $0.currentLevel > $1.currentLevel }
            .prefix(5)
            .map { $0 } ?? []
    }

    var activeQuests: [Quest] {
        character?.quests.filter { $0.isActive && !$0.isCompletedToday } ?? []
    }
}
