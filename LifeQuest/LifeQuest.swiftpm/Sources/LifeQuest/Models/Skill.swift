import Foundation
import SwiftData

/// A trainable skill that gains XP through activities
@Model
class Skill {
    var id: UUID
    var skillID: String          // Unique identifier (e.g., "strength", "focus")
    var name: String             // Display name
    var skillDescription: String // What this skill represents
    var domain: SkillDomain

    // Progression
    var currentLevel: Int
    var currentXP: Int           // XP within current level
    var totalXP: Int             // Lifetime XP in this skill
    var xpToNextLevel: Int

    // Tracking
    var lastTrainedAt: Date?
    var timesTrainedTotal: Int
    var currentStreak: Int       // Days in a row
    var longestStreak: Int

    // Relationship
    var character: Character?

    init(
        skillID: String,
        name: String,
        description: String,
        domain: SkillDomain,
        startingLevel: Int = 1
    ) {
        self.id = UUID()
        self.skillID = skillID
        self.name = name
        self.skillDescription = description
        self.domain = domain
        self.currentLevel = startingLevel
        self.currentXP = 0
        self.totalXP = Self.totalXPForLevel(startingLevel)
        self.xpToNextLevel = Self.xpRequiredForLevel(startingLevel + 1) - Self.totalXPForLevel(startingLevel)
        self.lastTrainedAt = nil
        self.timesTrainedTotal = 0
        self.currentStreak = 0
        self.longestStreak = 0
    }

    // MARK: - XP Calculations

    /// XP required to reach a specific level (cumulative)
    static func totalXPForLevel(_ level: Int) -> Int {
        guard level > 1 else { return 0 }
        return Int(pow(Double(level - 1), 1.5) * 100)
    }

    /// XP required for the next level specifically
    static func xpRequiredForLevel(_ level: Int) -> Int {
        return totalXPForLevel(level) - totalXPForLevel(level - 1)
    }

    /// Progress percentage to next level (0.0 - 1.0)
    var progressToNextLevel: Double {
        guard xpToNextLevel > 0 else { return 1.0 }
        return Double(currentXP) / Double(xpToNextLevel)
    }

    /// Award XP and handle level ups
    @discardableResult
    func awardXP(_ amount: Int) -> [LevelUp] {
        var levelUps: [LevelUp] = []
        var remainingXP = amount

        currentXP += remainingXP
        totalXP += remainingXP

        // Check for level ups
        while currentXP >= xpToNextLevel && currentLevel < 100 {
            currentXP -= xpToNextLevel
            currentLevel += 1
            xpToNextLevel = Self.xpRequiredForLevel(currentLevel + 1)

            levelUps.append(LevelUp(
                skillID: skillID,
                skillName: name,
                newLevel: currentLevel
            ))
        }

        // Cap at level 100
        if currentLevel >= 100 {
            currentLevel = 100
            currentXP = 0
        }

        // Update tracking
        let now = Date()
        updateStreak(trainedAt: now)
        lastTrainedAt = now
        timesTrainedTotal += 1

        return levelUps
    }

    private func updateStreak(trainedAt: Date) {
        guard let lastTrained = lastTrainedAt else {
            currentStreak = 1
            longestStreak = max(longestStreak, 1)
            return
        }

        let calendar = Calendar.current
        let daysSinceLastTraining = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: lastTrained),
            to: calendar.startOfDay(for: trainedAt)
        ).day ?? 0

        switch daysSinceLastTraining {
        case 0:
            // Same day, streak unchanged
            break
        case 1:
            // Consecutive day
            currentStreak += 1
            longestStreak = max(longestStreak, currentStreak)
        default:
            // Streak broken
            currentStreak = 1
        }
    }
}

// MARK: - Skill Domain

enum SkillDomain: String, Codable, CaseIterable {
    case physical = "Physical"
    case mental = "Mental"
    case social = "Social"
    case professional = "Professional"
    case maintenance = "Maintenance"

    var icon: String {
        switch self {
        case .physical: return "figure.run"
        case .mental: return "brain.head.profile"
        case .social: return "person.2"
        case .professional: return "briefcase"
        case .maintenance: return "heart"
        }
    }

    var color: String {
        switch self {
        case .physical: return "red"
        case .mental: return "purple"
        case .social: return "blue"
        case .professional: return "orange"
        case .maintenance: return "green"
        }
    }
}

// MARK: - Level Up Event

struct LevelUp: Identifiable {
    let id = UUID()
    let skillID: String
    let skillName: String
    let newLevel: Int
    let timestamp = Date()
}

// MARK: - Default Skills

extension Skill {
    static let defaultSkills: [(id: String, name: String, description: String, domain: SkillDomain)] = [
        // Physical
        ("strength", "Strength", "Raw power, lifting, resistance training", .physical),
        ("endurance", "Endurance", "Cardiovascular fitness, stamina", .physical),
        ("mobility", "Mobility", "Flexibility, range of motion, agility", .physical),
        ("recovery", "Recovery", "Ability to heal and restore", .physical),

        // Mental
        ("focus", "Focus", "Concentration, deep work ability", .mental),
        ("learning", "Learning", "Acquiring new knowledge", .mental),
        ("problem_solving", "Problem Solving", "Analytical thinking, debugging", .mental),
        ("creativity", "Creativity", "Novel ideation, artistic expression", .mental),

        // Social
        ("communication", "Communication", "Clear expression, writing, speaking", .social),
        ("leadership", "Leadership", "Guiding others, decision-making", .social),
        ("empathy", "Empathy", "Understanding others' perspectives", .social),
        ("networking", "Networking", "Building professional connections", .social),

        // Professional (defaults - user can customize)
        ("programming", "Programming", "Software development expertise", .professional),
        ("design", "Design", "Visual and UX design skills", .professional),
        ("writing", "Writing", "Written communication and content", .professional),

        // Maintenance
        ("sleep", "Sleep", "Rest quality and consistency", .maintenance),
        ("nutrition", "Nutrition", "Healthy eating habits", .maintenance),
        ("stress_management", "Stress Management", "Handling pressure, relaxation", .maintenance),
        ("finance", "Finance", "Money management", .maintenance),
    ]

    static func createDefaultSkills() -> [Skill] {
        defaultSkills.map { data in
            Skill(
                skillID: data.id,
                name: data.name,
                description: data.description,
                domain: data.domain,
                startingLevel: 1
            )
        }
    }
}
