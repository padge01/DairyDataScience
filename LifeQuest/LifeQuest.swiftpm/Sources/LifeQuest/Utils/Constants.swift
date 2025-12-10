import SwiftUI

/// App-wide constants and configuration
enum Constants {
    // MARK: - App Info
    static let appName = "LifeQuest"
    static let appVersion = "1.0.0"

    // MARK: - Colors
    enum Colors {
        static let primary = Color.indigo
        static let secondary = Color.purple
        static let accent = Color.orange

        static let health = Color.red
        static let energy = Color.blue
        static let xp = Color.yellow

        static let physical = Color.red
        static let mental = Color.purple
        static let social = Color.blue
        static let professional = Color.orange
        static let maintenance = Color.green

        static func forDomain(_ domain: SkillDomain) -> Color {
            switch domain {
            case .physical: return physical
            case .mental: return mental
            case .social: return social
            case .professional: return professional
            case .maintenance: return maintenance
            }
        }

        static func forStreakTier(_ tier: StreakTier) -> Color {
            switch tier {
            case .starting: return .gray
            case .building: return .blue
            case .consistent: return .green
            case .dedicated: return .yellow
            case .habitFormed: return .orange
            case .lifestyle: return .red
            case .mastery: return .purple
            }
        }
    }

    // MARK: - Layout
    enum Layout {
        static let padding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let cornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 24
    }

    // MARK: - Animation
    enum Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let levelUp = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
    }

    // MARK: - Progression
    enum Progression {
        static let maxLevel = 100
        static let majorSkillCount = 5
        static let minorSkillCount = 5
        static let skillLevelsPerCharacterLevel = 10
    }

    // MARK: - Streaks
    enum Streaks {
        static let gracePeriodDays = 1
        static let maxMultiplier = 2.5

        static func multiplier(forDays days: Int) -> Double {
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
    }

    // MARK: - Health & Energy
    enum Vitality {
        static let baseHealth = 100
        static let baseEnergy = 100
        static let healthPerVitality = 10
        static let energyPerWillpower = 10
        static let exhaustedThreshold = 0.25
        static let tiredThreshold = 0.5
    }

    // MARK: - XP
    enum XP {
        static let microActivity = 5...10
        static let smallActivity = 15...25
        static let mediumActivity = 30...50
        static let largeActivity = 60...100
        static let majorActivity = 150...300
    }
}

// MARK: - Date Formatting

extension Date {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }

    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }

    var dayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }
}

// MARK: - Number Formatting

extension Int {
    var abbreviated: String {
        if self >= 1000 {
            return String(format: "%.1fK", Double(self) / 1000.0)
        }
        return String(self)
    }
}

extension Double {
    var percentString: String {
        String(format: "%.0f%%", self * 100)
    }
}
