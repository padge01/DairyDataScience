import Foundation
import SwiftData

/// The player's character - their life stats and progression
@Model
class Character {
    var id: UUID
    var name: String
    var createdAt: Date

    // Core progression
    var level: Int
    var totalXP: Int
    var xpToNextLevel: Int

    // Vitality meters (Witcher-style)
    var currentHealth: Int
    var maxHealth: Int
    var currentEnergy: Int
    var maxEnergy: Int
    var restDebt: Int

    // Attributes (increase on level up)
    var vitality: Int      // Governs max health
    var willpower: Int     // Governs max energy
    var charisma: Int      // Social effectiveness
    var expertise: Int     // Professional XP bonus
    var balance: Int       // Recovery rate

    // Skill configuration
    var majorSkillIDs: [String]  // 5 max - count toward leveling
    var minorSkillIDs: [String]  // 5 max - partial level contribution

    // Relationships
    @Relationship(deleteRule: .cascade) var skills: [Skill]
    @Relationship(deleteRule: .cascade) var activities: [Activity]
    @Relationship(deleteRule: .cascade) var quests: [Quest]
    @Relationship(deleteRule: .cascade) var memories: [Memory]

    // Settings
    var dailyResetHour: Int  // When daily quests reset (default 4am)
    var weeklyResetDay: Int  // Day of week for weekly reset (1=Monday)

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()

        // Starting stats
        self.level = 1
        self.totalXP = 0
        self.xpToNextLevel = 100

        // Full meters to start
        self.currentHealth = 100
        self.maxHealth = 100
        self.currentEnergy = 100
        self.maxEnergy = 100
        self.restDebt = 0

        // Base attributes
        self.vitality = 10
        self.willpower = 10
        self.charisma = 10
        self.expertise = 10
        self.balance = 10

        // Empty skill config (set during character creation)
        self.majorSkillIDs = []
        self.minorSkillIDs = []

        // Relationships
        self.skills = []
        self.activities = []
        self.quests = []
        self.memories = []

        // Defaults
        self.dailyResetHour = 4
        self.weeklyResetDay = 1
    }

    // MARK: - Computed Properties

    var healthPercentage: Double {
        guard maxHealth > 0 else { return 0 }
        return Double(currentHealth) / Double(maxHealth)
    }

    var energyPercentage: Double {
        guard maxEnergy > 0 else { return 0 }
        return Double(currentEnergy) / Double(maxEnergy)
    }

    var isExhausted: Bool {
        healthPercentage < 0.25
    }

    var isDrained: Bool {
        energyPercentage < 0.25
    }

    var xpMultiplier: Double {
        var multiplier = 1.0

        // Health penalty
        if healthPercentage < 0.5 {
            multiplier *= 0.75
        } else if healthPercentage < 0.25 {
            multiplier *= 0.5
        }

        // Energy penalty
        if energyPercentage < 0.5 {
            multiplier *= 0.875
        } else if energyPercentage < 0.25 {
            multiplier *= 0.75
        }

        return multiplier
    }

    // MARK: - Methods

    func majorSkills() -> [Skill] {
        skills.filter { majorSkillIDs.contains($0.skillID) }
    }

    func minorSkills() -> [Skill] {
        skills.filter { minorSkillIDs.contains($0.skillID) }
    }

    func miscSkills() -> [Skill] {
        skills.filter {
            !majorSkillIDs.contains($0.skillID) &&
            !minorSkillIDs.contains($0.skillID)
        }
    }

    func skill(byID id: String) -> Skill? {
        skills.first { $0.skillID == id }
    }

    func updateMaxStats() {
        maxHealth = 100 + (vitality * 10)
        maxEnergy = 100 + (willpower * 10)
    }
}

// MARK: - Character Status

extension Character {
    enum Status: String {
        case healthy = "Healthy"
        case tired = "Tired"
        case exhausted = "Exhausted"
        case drained = "Drained"
        case burnout = "Burnout"

        var description: String {
            switch self {
            case .healthy: return "Ready for anything"
            case .tired: return "Could use some rest"
            case .exhausted: return "XP gains reduced"
            case .drained: return "Mental capacity limited"
            case .burnout: return "Rest required to progress"
            }
        }
    }

    var status: Status {
        if currentHealth == 0 || currentEnergy == 0 {
            return .burnout
        } else if isExhausted {
            return .exhausted
        } else if isDrained {
            return .drained
        } else if healthPercentage < 0.5 || energyPercentage < 0.5 {
            return .tired
        }
        return .healthy
    }
}
