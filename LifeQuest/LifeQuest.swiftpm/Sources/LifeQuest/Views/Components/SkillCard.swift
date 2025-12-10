import SwiftUI

/// Polished skill card with domain color and progress
struct SkillCard: View {
    let skill: Skill
    var isMajor: Bool = false
    var isMinor: Bool = false
    var showProgress: Bool = true
    var onTap: (() -> Void)? = nil

    @State private var isPressed = false

    var domainColor: Color {
        Theme.Colors.forDomain(skill.domain)
    }

    var body: some View {
        Button {
            onTap?()
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                // Domain icon with background
                ZStack {
                    Circle()
                        .fill(domainColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: skill.domain.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(domainColor)
                }

                // Skill info
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    HStack(spacing: Theme.Spacing.xs) {
                        Text(skill.name)
                            .font(Theme.Typography.labelLarge)
                            .foregroundStyle(Theme.Colors.textPrimary)

                        if isMajor {
                            SkillTypeBadge(type: .major)
                        } else if isMinor {
                            SkillTypeBadge(type: .minor)
                        }
                    }

                    if showProgress {
                        SkillProgressBar(
                            progress: skill.progressToNextLevel,
                            color: domainColor
                        )
                    }
                }

                Spacer()

                // Level display
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Lv")
                        .font(Theme.Typography.labelSmall)
                        .foregroundStyle(Theme.Colors.textTertiary)

                    Text("\(skill.currentLevel)")
                        .font(Theme.Typography.statMedium)
                        .foregroundStyle(domainColor)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.lg)
                    .stroke(domainColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(PressEffectButtonStyle())
    }
}

/// Compact skill progress bar
struct SkillProgressBar: View {
    let progress: Double
    let color: Color
    var height: CGFloat = 4

    @State private var animatedProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(0.15))

                Capsule()
                    .fill(color)
                    .frame(width: geo.size.width * animatedProgress)
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(Theme.Animation.slow) {
                animatedProgress = CGFloat(progress)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(Theme.Animation.standard) {
                animatedProgress = CGFloat(newValue)
            }
        }
    }
}

/// Badge for Major/Minor skill designation
struct SkillTypeBadge: View {
    enum SkillType {
        case major, minor

        var label: String {
            switch self {
            case .major: return "MAJOR"
            case .minor: return "MINOR"
            }
        }

        var color: Color {
            switch self {
            case .major: return Theme.Colors.xp
            case .minor: return Theme.Colors.info
            }
        }
    }

    let type: SkillType

    var body: some View {
        Text(type.label)
            .font(.system(size: 9, weight: .bold))
            .foregroundStyle(type.color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(type.color.opacity(0.15))
            .clipShape(Capsule())
    }
}

/// Skill radar chart for character overview
struct SkillRadarChart: View {
    let skills: [(name: String, level: Int, color: Color)]
    var size: CGFloat = 200

    var body: some View {
        ZStack {
            // Background web
            ForEach(0..<5) { ring in
                PolygonShape(sides: skills.count, scale: CGFloat(ring + 1) / 5.0)
                    .stroke(Theme.Colors.textTertiary.opacity(0.2), lineWidth: 1)
            }

            // Skill area
            PolygonShape(
                sides: skills.count,
                values: skills.map { CGFloat($0.level) / 100.0 }
            )
            .fill(Theme.Colors.primaryFallback.opacity(0.2))

            PolygonShape(
                sides: skills.count,
                values: skills.map { CGFloat($0.level) / 100.0 }
            )
            .stroke(Theme.Colors.primaryFallback, lineWidth: 2)

            // Skill points
            ForEach(0..<skills.count, id: \.self) { index in
                let angle = (2 * .pi / CGFloat(skills.count)) * CGFloat(index) - .pi / 2
                let radius = (size / 2) * (CGFloat(skills[index].level) / 100.0)
                let x = cos(angle) * radius
                let y = sin(angle) * radius

                Circle()
                    .fill(skills[index].color)
                    .frame(width: 8, height: 8)
                    .shadow(color: skills[index].color.opacity(0.5), radius: 4)
                    .offset(x: x, y: y)
            }

            // Labels
            ForEach(0..<skills.count, id: \.self) { index in
                let angle = (2 * .pi / CGFloat(skills.count)) * CGFloat(index) - .pi / 2
                let labelRadius = (size / 2) + 20
                let x = cos(angle) * labelRadius
                let y = sin(angle) * labelRadius

                Text(skills[index].name)
                    .font(Theme.Typography.labelSmall)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .offset(x: x, y: y)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Polygon shape for radar chart
struct PolygonShape: Shape {
    let sides: Int
    var scale: CGFloat = 1.0
    var values: [CGFloat]? = nil

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 * scale

        for i in 0..<sides {
            let angle = (2 * .pi / CGFloat(sides)) * CGFloat(i) - .pi / 2
            let r = values != nil ? radius * values![i] : radius
            let x = center.x + cos(angle) * r
            let y = center.y + sin(angle) * r

            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()

        return path
    }
}

/// Skill domain header
struct DomainHeader: View {
    let domain: SkillDomain
    let skillCount: Int
    let averageLevel: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: domain.icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Colors.forDomain(domain))

            Text(domain.rawValue)
                .font(Theme.Typography.headlineSmall)
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer()

            Text("\(skillCount) skills")
                .font(Theme.Typography.bodySmall)
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("Avg Lv. \(averageLevel)")
                .font(Theme.Typography.labelSmall)
                .foregroundStyle(Theme.Colors.forDomain(domain))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.Colors.forDomain(domain).opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            // Sample skill cards
            SkillCard(
                skill: Skill(skillID: "strength", name: "Strength", description: "Raw power", domain: .physical, startingLevel: 15),
                isMajor: true
            )

            SkillCard(
                skill: Skill(skillID: "focus", name: "Focus", description: "Concentration", domain: .mental, startingLevel: 8),
                isMinor: true
            )

            DomainHeader(domain: .physical, skillCount: 4, averageLevel: 12)
        }
        .padding()
    }
    .background(Theme.Colors.background)
}
