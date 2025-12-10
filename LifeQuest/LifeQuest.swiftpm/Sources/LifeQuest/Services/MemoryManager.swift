import Foundation
import SwiftData

/// Manages AI memory - storing, retrieving, and consolidating context
@Observable
class MemoryManager {
    private var modelContext: ModelContext
    private var aiService: AIService

    // Cache for quick access
    private var recentEpisodes: [Memory] = []
    private var activePatterns: [Memory] = []

    init(modelContext: ModelContext, aiService: AIService) {
        self.modelContext = modelContext
        self.aiService = aiService
    }

    // MARK: - Memory Creation

    /// Create an episodic memory from an activity
    func recordActivity(_ activity: Activity, for character: Character) {
        let memory = Memory(
            type: .episodic,
            content: activity.displayDescription,
            importance: calculateActivityImportance(activity)
        )

        memory.relatedActivityIDs = [activity.id]
        memory.relatedSkillIDs = activity.skillGains.map { $0.skillID }
        memory.character = character

        character.memories.append(memory)
        recentEpisodes.insert(memory, at: 0)

        // Keep cache bounded
        if recentEpisodes.count > 50 {
            recentEpisodes.removeLast()
        }
    }

    private func calculateActivityImportance(_ activity: Activity) -> Double {
        var importance = 0.5

        // Higher XP = more important
        let xp = activity.totalXPAwarded
        if xp > 50 { importance += 0.2 }
        if xp > 100 { importance += 0.1 }

        // Multiple skills = more complex activity
        if activity.skillsTrainedCount > 2 {
            importance += 0.1
        }

        return min(1.0, importance)
    }

    /// Add a semantic memory (fact about the user)
    func recordFact(
        _ fact: String,
        relatedSkills: [String] = [],
        for character: Character
    ) {
        let memory = Memory(
            type: .semantic,
            content: fact,
            importance: 0.7
        )
        memory.relatedSkillIDs = relatedSkills
        memory.character = character

        character.memories.append(memory)
    }

    /// Add a preference
    func recordPreference(
        _ preference: String,
        for character: Character
    ) {
        let memory = Memory(
            type: .preference,
            content: preference,
            importance: 0.8
        )
        memory.character = character
        character.memories.append(memory)
    }

    // MARK: - Context Building

    /// Build context string for AI prompts
    func buildContext(
        for character: Character,
        maxTokens: Int = 1000
    ) -> String {
        let memories = character.memories
        return Memory.buildContext(from: memories, maxTokens: maxTokens)
    }

    /// Get relevant context for a specific query
    func getRelevantContext(
        for query: String,
        character: Character,
        maxMemories: Int = 10
    ) -> [Memory] {
        // Simple relevance: check for skill mentions
        let queryLower = query.lowercased()
        let skillKeywords = Skill.defaultSkills.map { $0.id }

        var relevant: [Memory] = []

        // Find memories related to mentioned skills
        for memory in character.memories {
            for keyword in skillKeywords {
                if queryLower.contains(keyword) &&
                   memory.relatedSkillIDs.contains(keyword) {
                    memory.reference()
                    relevant.append(memory)
                    break
                }
            }
        }

        // If no skill matches, return highest priority memories
        if relevant.isEmpty {
            relevant = character.memories
                .sorted { $0.contextPriority > $1.contextPriority }
        }

        return Array(relevant.prefix(maxMemories))
    }

    // MARK: - Pattern Detection

    /// Analyze recent activities and extract patterns
    func extractPatterns(for character: Character) async -> [Memory] {
        let recentActivities = character.activities
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(100)

        guard recentActivities.count >= 10 else {
            return [] // Not enough data
        }

        // Group activities by time of day
        let timePatterns = detectTimePatterns(Array(recentActivities))

        // Group by skill frequency
        let skillPatterns = detectSkillPatterns(Array(recentActivities))

        // Group by consistency
        let consistencyPatterns = detectConsistencyPatterns(character)

        var newPatterns: [Memory] = []
        newPatterns.append(contentsOf: timePatterns)
        newPatterns.append(contentsOf: skillPatterns)
        newPatterns.append(contentsOf: consistencyPatterns)

        // Save new patterns
        for pattern in newPatterns {
            pattern.character = character
            character.memories.append(pattern)
        }

        activePatterns = newPatterns
        return newPatterns
    }

    private func detectTimePatterns(_ activities: [Activity]) -> [Memory] {
        var patterns: [Memory] = []

        // Group by hour
        var hourCounts: [Int: Int] = [:]
        for activity in activities {
            let hour = Calendar.current.component(.hour, from: activity.timestamp)
            hourCounts[hour, default: 0] += 1
        }

        // Find peak hours
        let sorted = hourCounts.sorted { $0.value > $1.value }
        if let peak = sorted.first, peak.value >= 5 {
            let timeString = peak.key < 12 ? "\(peak.key)am" : "\(peak.key - 12)pm"
            let pattern = Memory(
                type: .pattern,
                content: "Most active around \(timeString)",
                importance: 0.6
            )
            pattern.patternConfidence = Double(peak.value) / Double(activities.count)
            patterns.append(pattern)
        }

        return patterns
    }

    private func detectSkillPatterns(_ activities: [Activity]) -> [Memory] {
        var patterns: [Memory] = []

        // Count skill training frequency
        var skillCounts: [String: Int] = [:]
        for activity in activities {
            for gain in activity.skillGains {
                skillCounts[gain.skillID, default: 0] += 1
            }
        }

        // Find dominant skills
        let sorted = skillCounts.sorted { $0.value > $1.value }
        if sorted.count >= 2 {
            let top = sorted.prefix(2).map { $0.key }
            let pattern = Memory(
                type: .pattern,
                content: "Focus areas: \(top.joined(separator: " and "))",
                importance: 0.7
            )
            pattern.relatedSkillIDs = top
            patterns.append(pattern)
        }

        // Find neglected skills
        let neglected = sorted.suffix(2).map { $0.key }
        if !neglected.isEmpty {
            let pattern = Memory(
                type: .pattern,
                content: "Less trained: \(neglected.joined(separator: ", "))",
                importance: 0.5
            )
            pattern.relatedSkillIDs = Array(neglected)
            patterns.append(pattern)
        }

        return patterns
    }

    private func detectConsistencyPatterns(_ character: Character) -> [Memory] {
        var patterns: [Memory] = []

        // Find quests with best streaks
        let questsByStreak = character.quests.sorted { $0.longestStreak > $1.longestStreak }

        if let best = questsByStreak.first, best.longestStreak >= 7 {
            let pattern = Memory(
                type: .pattern,
                content: "Best consistency: \(best.name) (\(best.longestStreak) day streak)",
                importance: 0.8
            )
            patterns.append(pattern)
        }

        // Find struggling quests
        let struggling = character.quests.filter {
            $0.completedCount > 5 && $0.longestStreak < 3
        }

        if let first = struggling.first {
            let pattern = Memory(
                type: .pattern,
                content: "Struggles with consistency: \(first.name)",
                importance: 0.6
            )
            patterns.append(pattern)
        }

        return patterns
    }

    // MARK: - Memory Maintenance

    /// Decay old memories and consolidate
    func performMaintenance(for character: Character) {
        let now = Date()

        for memory in character.memories {
            // Decay importance of old, unreferenced memories
            let daysSinceReference = Calendar.current.dateComponents(
                [.day],
                from: memory.lastReferencedAt,
                to: now
            ).day ?? 0

            if daysSinceReference > 7 {
                memory.decay(factor: 0.95)
            }
        }

        // Remove stale memories
        character.memories.removeAll { $0.isStale }
    }

    /// Consolidate episodic memories into patterns (called weekly)
    func consolidateMemories(for character: Character) async {
        let episodic = character.memories.filter { $0.memoryType == .episodic }

        guard episodic.count >= 20 else { return }

        // Use AI to summarize if available
        if aiService.isConfigured {
            await aiConsolidate(episodes: episodic, for: character)
        } else {
            // Simple consolidation: group by skill and summarize
            simpleConsolidate(episodes: episodic, for: character)
        }
    }

    private func simpleConsolidate(episodes: [Memory], for character: Character) {
        // Group by primary skill
        var bySkill: [String: [Memory]] = [:]
        for episode in episodes {
            if let firstSkill = episode.relatedSkillIDs.first {
                bySkill[firstSkill, default: []].append(episode)
            }
        }

        // Create summary patterns
        for (skillID, memories) in bySkill where memories.count >= 5 {
            let pattern = Memory.consolidateToPattern(
                episodes: memories,
                patternDescription: "Regularly trains \(skillID) (\(memories.count) sessions)",
                confidence: min(1.0, Double(memories.count) / 20.0)
            )
            pattern.character = character
            character.memories.append(pattern)

            // Remove consolidated episodes
            for memory in memories.prefix(memories.count - 5) {
                if let index = character.memories.firstIndex(where: { $0.id == memory.id }) {
                    character.memories.remove(at: index)
                }
            }
        }
    }

    private func aiConsolidate(episodes: [Memory], for character: Character) async {
        // TODO: Use AIService to generate better pattern summaries
        // For now, fall back to simple consolidation
        simpleConsolidate(episodes: episodes, for: character)
    }
}
