import SwiftUI

/// Animated character avatar with status indicators
struct CharacterAvatar: View {
    let name: String
    let level: Int
    var health: Double = 1.0
    var energy: Double = 1.0
    var size: CGFloat = 100
    var showLevel: Bool = true
    var showStatus: Bool = true

    @State private var pulseAnimation = false

    var statusColor: Color {
        if health < 0.25 || energy < 0.25 {
            return Theme.Colors.error
        } else if health < 0.5 || energy < 0.5 {
            return Theme.Colors.warning
        }
        return Theme.Colors.success
    }

    var body: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Theme.Colors.primaryFallback,
                            Theme.Colors.secondaryFallback,
                            Theme.Colors.primaryFallback
                        ],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: size + 8, height: size + 8)
                .blur(radius: 2)
                .opacity(pulseAnimation ? 0.8 : 0.4)

            // Avatar background
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Theme.Colors.surfaceElevated,
                            Theme.Colors.surface
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)

            // Border ring
            Circle()
                .stroke(Theme.Colors.primaryGradient, lineWidth: 3)
                .frame(width: size, height: size)

            // Initial letter
            Text(name.prefix(1).uppercased())
                .font(.system(size: size * 0.4, weight: .bold, design: .rounded))
                .foregroundStyle(Theme.Colors.primaryGradient)

            // Level badge
            if showLevel {
                LevelBadge(level: level, isActive: true, size: size * 0.35)
                    .offset(x: size * 0.35, y: size * 0.35)
            }

            // Status indicator
            if showStatus {
                Circle()
                    .fill(statusColor)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 2)
                    )
                    .offset(x: -size * 0.35, y: size * 0.35)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

/// Character header with name, level, and status
struct CharacterHeader: View {
    let character: Character

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            CharacterAvatar(
                name: character.name,
                level: character.level,
                health: character.healthPercentage,
                energy: character.energyPercentage
            )

            VStack(spacing: Theme.Spacing.xxs) {
                Text(character.name)
                    .font(Theme.Typography.headlineLarge)
                    .foregroundStyle(Theme.Colors.textPrimary)

                HStack(spacing: Theme.Spacing.xs) {
                    Text("Level \(character.level)")
                        .font(Theme.Typography.labelMedium)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Text("•")
                        .foregroundStyle(Theme.Colors.textTertiary)

                    StatusBadge(status: character.status)
                }
            }
        }
    }
}

/// Status badge (Healthy, Tired, etc.)
struct StatusBadge: View {
    let status: Character.Status

    var color: Color {
        switch status {
        case .healthy: return Theme.Colors.success
        case .tired: return Theme.Colors.warning
        case .exhausted, .drained: return Theme.Colors.warning
        case .burnout: return Theme.Colors.error
        }
    }

    var icon: String {
        switch status {
        case .healthy: return "checkmark.circle.fill"
        case .tired: return "moon.fill"
        case .exhausted: return "battery.25"
        case .drained: return "brain"
        case .burnout: return "exclamationmark.triangle.fill"
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Image(systemName: icon)
                .font(.system(size: 10))

            Text(status.rawValue)
                .font(Theme.Typography.labelSmall)
        }
        .foregroundStyle(color)
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, Theme.Spacing.xxxs)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

/// Vitality meters panel (Health, Energy, Rest)
struct VitalityPanel: View {
    let character: Character

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            // Health bar
            StatBar(
                label: "Health",
                value: character.currentHealth,
                maxValue: character.maxHealth,
                icon: Theme.Icons.health,
                color: Theme.Colors.health,
                glowColor: Theme.Colors.healthGlow
            )

            // Energy bar
            StatBar(
                label: "Energy",
                value: character.currentEnergy,
                maxValue: character.maxEnergy,
                icon: Theme.Icons.energy,
                color: Theme.Colors.energy,
                glowColor: Theme.Colors.energyGlow
            )

            // Rest debt indicator
            if character.restDebt > 0 {
                RestDebtIndicator(debt: character.restDebt)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }
}

/// Rest debt warning indicator
struct RestDebtIndicator: View {
    let debt: Int

    var severity: String {
        switch debt {
        case 1...5: return "Mild"
        case 6...10: return "Moderate"
        case 11...20: return "High"
        default: return "Critical"
        }
    }

    var color: Color {
        switch debt {
        case 1...5: return Theme.Colors.warning.opacity(0.8)
        case 6...10: return Theme.Colors.warning
        case 11...20: return Theme.Colors.error.opacity(0.8)
        default: return Theme.Colors.error
        }
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: Theme.Icons.restDebt)
                .font(.system(size: 16))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text("Rest Debt")
                    .font(Theme.Typography.labelSmall)
                    .foregroundStyle(Theme.Colors.textSecondary)

                Text("\(severity) (\(debt) hours)")
                    .font(Theme.Typography.labelMedium)
                    .foregroundStyle(color)
            }

            Spacer()

            Text("Sleep to recover")
                .font(Theme.Typography.bodySmall)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(Theme.Spacing.sm)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
    }
}

/// Attribute display row
struct AttributeRow: View {
    let name: String
    let value: Int
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 20)

            Text(name)
                .font(Theme.Typography.labelMedium)
                .foregroundStyle(Theme.Colors.textSecondary)

            Spacer()

            Text("\(value)")
                .font(Theme.Typography.statSmall)
                .foregroundStyle(color)
        }
    }
}

/// Attributes panel
struct AttributesPanel: View {
    let character: Character

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Attributes")
                .font(Theme.Typography.headlineSmall)
                .foregroundStyle(Theme.Colors.textPrimary)

            VStack(spacing: Theme.Spacing.xs) {
                AttributeRow(name: "Vitality", value: character.vitality, icon: "heart.fill", color: Theme.Colors.health)
                AttributeRow(name: "Willpower", value: character.willpower, icon: "brain", color: Theme.Colors.mental)
                AttributeRow(name: "Charisma", value: character.charisma, icon: "person.wave.2.fill", color: Theme.Colors.social)
                AttributeRow(name: "Expertise", value: character.expertise, icon: "star.fill", color: Theme.Colors.professional)
                AttributeRow(name: "Balance", value: character.balance, icon: "scalemass.fill", color: Theme.Colors.maintenance)
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }
}

#Preview {
    VStack(spacing: 24) {
        CharacterAvatar(name: "Marcus", level: 12, health: 0.8, energy: 0.6)

        CharacterHeader(
            character: {
                let c = Character(name: "Marcus")
                c.level = 12
                c.currentHealth = 80
                c.currentEnergy = 60
                return c
            }()
        )
    }
    .padding()
    .background(Theme.Colors.background)
}
