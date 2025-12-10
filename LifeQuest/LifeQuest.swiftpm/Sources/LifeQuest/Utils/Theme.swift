import SwiftUI

// MARK: - Design System

/// LifeQuest Design System
/// A "Modern Fantasy" aesthetic combining clean UI with RPG warmth
enum Theme {

    // MARK: - Color Palette

    enum Colors {
        // Primary brand colors
        static let primary = Color("Primary", bundle: nil)
        static let secondary = Color("Secondary", bundle: nil)
        static let accent = Color("Accent", bundle: nil)

        // Fallback colors (used when assets aren't available)
        static let primaryFallback = Color(hex: "6366F1")     // Indigo
        static let secondaryFallback = Color(hex: "8B5CF6")   // Purple
        static let accentFallback = Color(hex: "F59E0B")      // Amber/Gold

        // Surface colors
        static let background = Color(hex: "0F0F14")          // Deep charcoal
        static let surface = Color(hex: "1A1A24")             // Elevated surface
        static let surfaceElevated = Color(hex: "252532")     // Cards, modals
        static let surfaceHighlight = Color(hex: "2F2F3D")    // Hover states

        // Text colors
        static let textPrimary = Color(hex: "F4F4F5")         // Primary text
        static let textSecondary = Color(hex: "A1A1AA")       // Secondary text
        static let textTertiary = Color(hex: "71717A")        // Muted text
        static let textInverse = Color(hex: "18181B")         // Text on light

        // Semantic colors
        static let success = Color(hex: "22C55E")             // Green
        static let warning = Color(hex: "F59E0B")             // Amber
        static let error = Color(hex: "EF4444")               // Red
        static let info = Color(hex: "3B82F6")                // Blue

        // RPG-themed stat colors
        static let health = Color(hex: "DC2626")              // Deep red
        static let healthGlow = Color(hex: "FCA5A5")          // Red glow
        static let energy = Color(hex: "3B82F6")              // Blue
        static let energyGlow = Color(hex: "93C5FD")          // Blue glow
        static let xp = Color(hex: "F59E0B")                  // Gold
        static let xpGlow = Color(hex: "FCD34D")              // Gold glow

        // Domain colors
        static let physical = Color(hex: "EF4444")            // Red
        static let mental = Color(hex: "8B5CF6")              // Purple
        static let social = Color(hex: "3B82F6")              // Blue
        static let professional = Color(hex: "F97316")        // Orange
        static let maintenance = Color(hex: "22C55E")         // Green

        // Streak tier colors
        static let streakStarting = Color(hex: "71717A")      // Gray
        static let streakBuilding = Color(hex: "3B82F6")      // Blue
        static let streakConsistent = Color(hex: "22C55E")    // Green
        static let streakDedicated = Color(hex: "EAB308")     // Yellow
        static let streakHabit = Color(hex: "F97316")         // Orange
        static let streakLifestyle = Color(hex: "EF4444")     // Red
        static let streakMastery = Color(hex: "A855F7")       // Purple

        // Gradients
        static let primaryGradient = LinearGradient(
            colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let goldGradient = LinearGradient(
            colors: [Color(hex: "F59E0B"), Color(hex: "FBBF24")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let healthGradient = LinearGradient(
            colors: [Color(hex: "DC2626"), Color(hex: "EF4444")],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let energyGradient = LinearGradient(
            colors: [Color(hex: "2563EB"), Color(hex: "3B82F6")],
            startPoint: .leading,
            endPoint: .trailing
        )

        static let surfaceGradient = LinearGradient(
            colors: [Color(hex: "1A1A24"), Color(hex: "0F0F14")],
            startPoint: .top,
            endPoint: .bottom
        )

        // Domain color helper
        static func forDomain(_ domain: SkillDomain) -> Color {
            switch domain {
            case .physical: return physical
            case .mental: return mental
            case .social: return social
            case .professional: return professional
            case .maintenance: return maintenance
            }
        }

        // Streak color helper
        static func forStreak(_ tier: StreakTier) -> Color {
            switch tier {
            case .starting: return streakStarting
            case .building: return streakBuilding
            case .consistent: return streakConsistent
            case .dedicated: return streakDedicated
            case .habitFormed: return streakHabit
            case .lifestyle: return streakLifestyle
            case .mastery: return streakMastery
            }
        }
    }

    // MARK: - Typography

    enum Typography {
        // Display - Large headers, level up screens
        static let displayLarge = Font.system(size: 48, weight: .bold, design: .rounded)
        static let displayMedium = Font.system(size: 36, weight: .bold, design: .rounded)
        static let displaySmall = Font.system(size: 28, weight: .bold, design: .rounded)

        // Headlines - Section titles
        static let headlineLarge = Font.system(size: 24, weight: .semibold, design: .rounded)
        static let headlineMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
        static let headlineSmall = Font.system(size: 17, weight: .semibold, design: .rounded)

        // Body - Main content
        static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)
        static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)
        static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)

        // Labels - UI elements
        static let labelLarge = Font.system(size: 15, weight: .medium, design: .default)
        static let labelMedium = Font.system(size: 13, weight: .medium, design: .default)
        static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

        // Monospace - Stats, numbers
        static let statLarge = Font.system(size: 32, weight: .bold, design: .monospaced)
        static let statMedium = Font.system(size: 20, weight: .bold, design: .monospaced)
        static let statSmall = Font.system(size: 14, weight: .semibold, design: .monospaced)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxxs: CGFloat = 2
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }

    // MARK: - Corner Radius

    enum Radius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = 9999
    }

    // MARK: - Shadows

    enum Shadows {
        static let sm = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let md = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        static let lg = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        static let xl = Shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)

        // Glow effects
        static func glow(color: Color, radius: CGFloat = 8) -> Shadow {
            Shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
        }
    }

    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }

    // MARK: - Animation

    enum Animation {
        static let quick = SwiftUI.Animation.easeOut(duration: 0.15)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.4)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
        static let levelUp = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.5)
    }

    // MARK: - Icons

    enum Icons {
        // Navigation
        static let character = "person.fill"
        static let quests = "scroll.fill"
        static let log = "plus.circle.fill"
        static let coach = "sparkles"
        static let settings = "gearshape.fill"

        // Stats
        static let health = "heart.fill"
        static let energy = "bolt.fill"
        static let xp = "star.fill"
        static let level = "shield.fill"
        static let restDebt = "moon.zzz.fill"

        // Domains
        static let physical = "figure.strengthtraining.traditional"
        static let mental = "brain.head.profile"
        static let social = "person.2.fill"
        static let professional = "briefcase.fill"
        static let maintenance = "heart.text.square.fill"

        // Actions
        static let complete = "checkmark.circle.fill"
        static let incomplete = "circle"
        static let add = "plus.circle.fill"
        static let streak = "flame.fill"
        static let auto = "bolt.heart.fill"

        // Misc
        static let insight = "lightbulb.fill"
        static let pattern = "chart.line.uptrend.xyaxis"
        static let levelUp = "arrow.up.circle.fill"
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers

extension View {
    func cardStyle() -> some View {
        self
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }

    func glowEffect(color: Color, radius: CGFloat = 8) -> some View {
        self.shadow(color: color.opacity(0.5), radius: radius, x: 0, y: 0)
    }

    func pressEffect() -> some View {
        self.buttonStyle(PressEffectButtonStyle())
    }
}

// MARK: - Button Styles

struct PressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.labelLarge)
            .foregroundStyle(.white)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
            .background(
                isEnabled
                    ? Theme.Colors.primaryGradient
                    : LinearGradient(colors: [Theme.Colors.textTertiary], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Typography.labelLarge)
            .foregroundStyle(Theme.Colors.primaryFallback)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.primaryFallback.opacity(configuration.isPressed ? 0.15 : 0.1))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
            .animation(Theme.Animation.quick, value: configuration.isPressed)
    }
}
