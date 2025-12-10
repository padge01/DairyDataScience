import Foundation
import SwiftData

/// AI memory for context accumulation and pattern recognition
@Model
class Memory {
    var id: UUID
    var createdAt: Date
    var lastReferencedAt: Date

    // Content
    var memoryType: MemoryType
    var content: String
    var summary: String?         // Condensed version for context window

    // Importance for pruning
    var importance: Double       // 0.0 - 1.0
    var referenceCount: Int      // How often it's been used

    // Relationships
    var relatedSkillIDs: [String]
    var relatedActivityIDs: [UUID]
    var character: Character?

    // For pattern memories
    var patternConfidence: Double?
    var patternEvidence: [String]?  // Activity descriptions that support this

    init(
        type: MemoryType,
        content: String,
        importance: Double = 0.5
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.lastReferencedAt = Date()
        self.memoryType = type
        self.content = content
        self.summary = nil
        self.importance = importance
        self.referenceCount = 0
        self.relatedSkillIDs = []
        self.relatedActivityIDs = []
        self.patternConfidence = nil
        self.patternEvidence = nil
    }

    // MARK: - Methods

    func reference() {
        lastReferencedAt = Date()
        referenceCount += 1
        // Boost importance when frequently referenced
        importance = min(1.0, importance + 0.05)
    }

    func decay(factor: Double = 0.95) {
        // Reduce importance over time if not referenced
        importance *= factor
    }

    var isStale: Bool {
        let daysSinceReference = Calendar.current.dateComponents(
            [.day],
            from: lastReferencedAt,
            to: Date()
        ).day ?? 0
        return daysSinceReference > 30 && importance < 0.3
    }

    var contextPriority: Double {
        // Score for inclusion in AI context window
        let recencyScore = 1.0 / (1.0 + Double(daysSinceCreation) / 7.0)
        let referenceScore = min(1.0, Double(referenceCount) / 10.0)
        return (importance * 0.4) + (recencyScore * 0.3) + (referenceScore * 0.3)
    }

    private var daysSinceCreation: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
}

// MARK: - Memory Types

enum MemoryType: String, Codable {
    case episodic = "Episodic"      // Specific events/activities
    case pattern = "Pattern"         // Recognized behavioral patterns
    case semantic = "Semantic"       // Facts about the user's life
    case insight = "Insight"         // AI-generated observations
    case preference = "Preference"   // User preferences/constraints

    var icon: String {
        switch self {
        case .episodic: return "clock"
        case .pattern: return "repeat"
        case .semantic: return "book"
        case .insight: return "lightbulb"
        case .preference: return "heart"
        }
    }

    var description: String {
        switch self {
        case .episodic: return "Specific events and activities"
        case .pattern: return "Recurring behavioral patterns"
        case .semantic: return "Facts about your life"
        case .insight: return "AI observations"
        case .preference: return "Your preferences"
        }
    }
}

// MARK: - Memory Context Builder

extension Memory {
    /// Build context string for AI prompts from a collection of memories
    static func buildContext(
        from memories: [Memory],
        maxTokens: Int = 1000,
        priorityThreshold: Double = 0.3
    ) -> String {
        // Filter and sort by priority
        let relevantMemories = memories
            .filter { $0.contextPriority >= priorityThreshold }
            .sorted { $0.contextPriority > $1.contextPriority }

        var context = ""
        var estimatedTokens = 0

        // Group by type for organized context
        let grouped = Dictionary(grouping: relevantMemories) { $0.memoryType }

        // Add patterns first (most useful for context)
        if let patterns = grouped[.pattern] {
            context += "## Behavioral Patterns\n"
            for memory in patterns.prefix(5) {
                let line = "- \(memory.content)\n"
                estimatedTokens += line.count / 4
                if estimatedTokens > maxTokens { break }
                context += line
            }
            context += "\n"
        }

        // Add insights
        if let insights = grouped[.insight] {
            context += "## Insights\n"
            for memory in insights.prefix(3) {
                let line = "- \(memory.content)\n"
                estimatedTokens += line.count / 4
                if estimatedTokens > maxTokens { break }
                context += line
            }
            context += "\n"
        }

        // Add semantic facts
        if let facts = grouped[.semantic] {
            context += "## About User\n"
            for memory in facts.prefix(5) {
                let line = "- \(memory.content)\n"
                estimatedTokens += line.count / 4
                if estimatedTokens > maxTokens { break }
                context += line
            }
            context += "\n"
        }

        // Add recent episodes if room
        if let episodes = grouped[.episodic], estimatedTokens < maxTokens * 3 / 4 {
            context += "## Recent Activities\n"
            for memory in episodes.prefix(5) {
                let line = "- \(memory.content)\n"
                estimatedTokens += line.count / 4
                if estimatedTokens > maxTokens { break }
                context += line
            }
        }

        return context
    }
}

// MARK: - Memory Consolidation

extension Memory {
    /// Create a pattern memory from multiple episodic memories
    static func consolidateToPattern(
        episodes: [Memory],
        patternDescription: String,
        confidence: Double
    ) -> Memory {
        let pattern = Memory(
            type: .pattern,
            content: patternDescription,
            importance: confidence
        )
        pattern.patternConfidence = confidence
        pattern.patternEvidence = episodes.map { $0.content }
        pattern.relatedActivityIDs = episodes.flatMap { $0.relatedActivityIDs }
        pattern.relatedSkillIDs = Array(Set(episodes.flatMap { $0.relatedSkillIDs }))
        return pattern
    }
}
