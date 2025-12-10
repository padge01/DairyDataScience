import Foundation
import SwiftData

/// Handles all XP calculations, leveling, and progression mechanics
@Observable
class ProgressionEngine {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - XP Awards

    /// Award XP to a skill with all multipliers applied
    func awardXP(
        to character: Character,
        skillID: String,
        baseAmount: Int,
        streakDays: Int = 0,
        source: String? = nil
    ) -> ProgressionResult {
        guard let skill = character.skill(byID: skillID) else {
            return ProgressionResult(success: false, error: "Skill not found: \(skillID)")
        }

        // Calculate multipliers
        let streakMultiplier = self.streakMultiplier(days: streakDays)
        let healthMultiplier = character.xpMultiplier

        let finalAmount = Int(Double(baseAmount) * streakMultiplier * healthMultiplier)

        // Award XP and capture level ups
        let levelUps = skill.awardXP(finalAmount)

        // Check for character level up
        let characterLevelUp = checkCharacterLevelUp(character)

        return ProgressionResult(
            success: true,
            xpAwarded: finalAmount,
            skillLevelUps: levelUps,
            characterLevelUp: characterLevelUp,
            multipliers: MultiplierBreakdown(
                streak: streakMultiplier,
                health: healthMultiplier,
                total: streakMultiplier * healthMultiplier
            )
        )
    }

    /// Process multiple skill gains from an activity
    func processSkillGains(
        character: Character,
        gains: [SkillGain],
        streakDays: Int = 0
    ) -> [ProgressionResult] {
        gains.map { gain in
            awardXP(
                to: character,
                skillID: gain.skillID,
                baseAmount: gain.amount,
                streakDays: streakDays,
                source: gain.reason
            )
        }
    }

    // MARK: - Streak Multiplier

    func streakMultiplier(days: Int) -> Double {
        switch days {
        case 0...3: return 1.0
        case 4...7: return 1.25
        case 8...14: return 1.5
        case 15...30: return 1.75
        case 31...60: return 2.0
        case 61...90: return 2.25
        default: return 2.5
        }
    }

    // MARK: - Character Leveling

    /// Check if character should level up based on major skill gains
    func checkCharacterLevelUp(_ character: Character) -> CharacterLevelUp? {
        let majorSkills = character.majorSkills()
        guard !majorSkills.isEmpty else { return nil }

        // Calculate total major skill levels
        let totalMajorLevels = majorSkills.reduce(0) { $0 + $1.currentLevel }
        let baseLine = majorSkills.count * 10 // Starting level for major skills

        // Levels gained since character creation
        let totalGains = totalMajorLevels - baseLine

        // Character levels up every 10 skill levels gained
        let expectedLevel = 1 + (totalGains / 10)

        if expectedLevel > character.level {
            // Level up!
            let oldLevel = character.level
            character.level = expectedLevel

            // Calculate attribute bonuses based on which domains grew
            let attributeGains = calculateAttributeGains(character: character)

            // Apply attribute gains
            character.vitality += attributeGains.vitality
            character.willpower += attributeGains.willpower
            character.charisma += attributeGains.charisma
            character.expertise += attributeGains.expertise
            character.balance += attributeGains.balance

            // Update max stats
            character.updateMaxStats()

            return CharacterLevelUp(
                oldLevel: oldLevel,
                newLevel: expectedLevel,
                attributeGains: attributeGains
            )
        }

        return nil
    }

    private func calculateAttributeGains(character: Character) -> AttributeGains {
        // Determine which domains contributed most to this level
        var domainContributions: [SkillDomain: Int] = [:]

        for skill in character.majorSkills() {
            domainContributions[skill.domain, default: 0] += skill.currentLevel
        }

        // Find dominant domain
        let sorted = domainContributions.sorted { $0.value > $1.value }

        var gains = AttributeGains()
        gains.addPoints(3) // 3 points per level

        // Primary domain gets 2 points, secondary gets 1
        if let primary = sorted.first {
            switch primary.key {
            case .physical: gains.vitality += 2
            case .mental: gains.willpower += 2
            case .social: gains.charisma += 2
            case .professional: gains.expertise += 2
            case .maintenance: gains.balance += 2
            }
        }

        if sorted.count > 1 {
            switch sorted[1].key {
            case .physical: gains.vitality += 1
            case .mental: gains.willpower += 1
            case .social: gains.charisma += 1
            case .professional: gains.expertise += 1
            case .maintenance: gains.balance += 1
            }
        }

        return gains
    }

    // MARK: - Recovery System

    /// Process sleep and update health/energy recovery
    func processRecovery(
        character: Character,
        sleepHours: Double,
        sleepQuality: SleepQuality = .normal
    ) {
        // Calculate health recovery
        let baseHealthRecovery = min(50, Int(sleepHours * 6))
        let qualityMultiplier = sleepQuality.multiplier

        let healthRecovered = Int(Double(baseHealthRecovery) * qualityMultiplier)
        character.currentHealth = min(character.maxHealth, character.currentHealth + healthRecovered)

        // Calculate energy recovery
        let baseEnergyRecovery = min(60, Int(sleepHours * 8))
        let energyRecovered = Int(Double(baseEnergyRecovery) * qualityMultiplier)
        character.currentEnergy = min(character.maxEnergy, character.currentEnergy + energyRecovered)

        // Update rest debt
        if sleepHours >= 8 {
            character.restDebt = max(0, character.restDebt - 3)
        } else if sleepHours >= 7 {
            character.restDebt = max(0, character.restDebt - 1)
        } else {
            character.restDebt += Int(7 - sleepHours)
        }
    }

    /// Deplete energy from an activity
    func consumeEnergy(character: Character, amount: Int) {
        character.currentEnergy = max(0, character.currentEnergy - amount)
    }

    /// Deplete health from intense activity
    func consumeHealth(character: Character, amount: Int) {
        character.currentHealth = max(0, character.currentHealth - amount)
    }
}

// MARK: - Result Types

struct ProgressionResult {
    var success: Bool
    var error: String?
    var xpAwarded: Int = 0
    var skillLevelUps: [LevelUp] = []
    var characterLevelUp: CharacterLevelUp?
    var multipliers: MultiplierBreakdown?
}

struct MultiplierBreakdown {
    var streak: Double
    var health: Double
    var total: Double
}

struct CharacterLevelUp {
    var oldLevel: Int
    var newLevel: Int
    var attributeGains: AttributeGains
}

struct AttributeGains {
    var vitality: Int = 0
    var willpower: Int = 0
    var charisma: Int = 0
    var expertise: Int = 0
    var balance: Int = 0

    var total: Int {
        vitality + willpower + charisma + expertise + balance
    }

    mutating func addPoints(_ points: Int) {
        // Default distribution if no domain preference
        let perAttribute = points / 5
        vitality += perAttribute
        willpower += perAttribute
        charisma += perAttribute
        expertise += perAttribute
        balance += perAttribute
    }
}

enum SleepQuality: String {
    case poor = "Poor"
    case normal = "Normal"
    case good = "Good"
    case excellent = "Excellent"

    var multiplier: Double {
        switch self {
        case .poor: return 0.5
        case .normal: return 1.0
        case .good: return 1.25
        case .excellent: return 1.5
        }
    }
}
