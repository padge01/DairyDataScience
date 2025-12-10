import SwiftUI

/// Animated stat bar with glow effect for Health/Energy/XP
struct StatBar: View {
    let label: String
    let value: Int
    let maxValue: Int
    let icon: String
    let color: Color
    let glowColor: Color
    var showLabel: Bool = true
    var height: CGFloat = 12

    @State private var animatedProgress: CGFloat = 0

    var progress: CGFloat {
        guard maxValue > 0 else { return 0 }
        return CGFloat(value) / CGFloat(maxValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            if showLabel {
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(color)

                    Text(label)
                        .font(Theme.Typography.labelMedium)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Spacer()

                    Text("\(value)")
                        .font(Theme.Typography.statSmall)
                        .foregroundStyle(color)
                    +
                    Text(" / \(maxValue)")
                        .font(Theme.Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    Capsule()
                        .fill(color.opacity(0.15))

                    // Animated fill
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * animatedProgress))
                        .shadow(color: glowColor.opacity(0.6), radius: 4, x: 0, y: 0)

                    // Shimmer effect on full bar
                    if animatedProgress > 0.95 {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.clear, .white.opacity(0.3), .clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * animatedProgress)
                    }
                }
            }
            .frame(height: height)
        }
        .onAppear {
            withAnimation(Theme.Animation.slow) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(Theme.Animation.standard) {
                animatedProgress = newValue
            }
        }
    }
}

/// Circular stat ring for compact displays
struct StatRing: View {
    let value: Int
    let maxValue: Int
    let icon: String
    let color: Color
    var size: CGFloat = 60
    var lineWidth: CGFloat = 6

    @State private var animatedProgress: CGFloat = 0

    var progress: CGFloat {
        guard maxValue > 0 else { return 0 }
        return CGFloat(value) / CGFloat(maxValue)
    }

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [color, color.opacity(0.7)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.5), radius: 4)

            // Icon
            Image(systemName: icon)
                .font(.system(size: size * 0.3, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(Theme.Animation.slow) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(Theme.Animation.standard) {
                animatedProgress = newValue
            }
        }
    }
}

/// XP Progress bar with level indicators
struct XPBar: View {
    let currentXP: Int
    let xpForLevel: Int
    let level: Int

    @State private var animatedProgress: CGFloat = 0
    @State private var showSparkle: Bool = false

    var progress: CGFloat {
        guard xpForLevel > 0 else { return 0 }
        return CGFloat(currentXP) / CGFloat(xpForLevel)
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            // Level indicators
            HStack {
                LevelBadge(level: level, isActive: true)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(currentXP) / \(xpForLevel) XP")
                        .font(Theme.Typography.labelSmall)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Text("\(Int(progress * 100))% to Level \(level + 1)")
                        .font(Theme.Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
            }

            // XP Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    Capsule()
                        .fill(Theme.Colors.xp.opacity(0.15))

                    // Fill
                    Capsule()
                        .fill(Theme.Colors.goldGradient)
                        .frame(width: max(0, geo.size.width * animatedProgress))
                        .shadow(color: Theme.Colors.xpGlow.opacity(0.6), radius: 6)

                    // Sparkle particles
                    if showSparkle {
                        SparkleOverlay()
                            .frame(width: geo.size.width * animatedProgress)
                    }
                }
            }
            .frame(height: 14)
        }
        .onAppear {
            withAnimation(Theme.Animation.slow) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            withAnimation(Theme.Animation.standard) {
                animatedProgress = newValue
            }
            // Trigger sparkle on XP gain
            if newValue > oldValue {
                triggerSparkle()
            }
        }
    }

    private func triggerSparkle() {
        showSparkle = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showSparkle = false
        }
    }
}

/// Level badge with shield design
struct LevelBadge: View {
    let level: Int
    var isActive: Bool = false
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            // Shield shape
            Image(systemName: "shield.fill")
                .font(.system(size: size))
                .foregroundStyle(
                    isActive
                        ? Theme.Colors.goldGradient
                        : LinearGradient(colors: [Theme.Colors.textTertiary], startPoint: .top, endPoint: .bottom)
                )
                .shadow(color: isActive ? Theme.Colors.xpGlow.opacity(0.5) : .clear, radius: 4)

            // Level number
            Text("\(level)")
                .font(.system(size: size * 0.35, weight: .bold, design: .rounded))
                .foregroundStyle(isActive ? Theme.Colors.textInverse : Theme.Colors.textSecondary)
                .offset(y: 2)
        }
    }
}

/// Sparkle particle overlay
struct SparkleOverlay: View {
    @State private var particles: [(id: UUID, x: CGFloat, y: CGFloat)] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles, id: \.id) { particle in
                    Image(systemName: "sparkle")
                        .font(.system(size: 8))
                        .foregroundStyle(Theme.Colors.xpGlow)
                        .position(x: particle.x * geo.size.width, y: particle.y * geo.size.height)
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .onAppear {
            generateParticles()
        }
    }

    private func generateParticles() {
        for _ in 0..<5 {
            let particle = (id: UUID(), x: CGFloat.random(in: 0.3...1.0), y: CGFloat.random(in: 0...1))
            withAnimation(.easeOut(duration: 0.3)) {
                particles.append(particle)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation {
                particles.removeAll()
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        StatBar(
            label: "Health",
            value: 75,
            maxValue: 100,
            icon: Theme.Icons.health,
            color: Theme.Colors.health,
            glowColor: Theme.Colors.healthGlow
        )

        StatBar(
            label: "Energy",
            value: 45,
            maxValue: 100,
            icon: Theme.Icons.energy,
            color: Theme.Colors.energy,
            glowColor: Theme.Colors.energyGlow
        )

        XPBar(currentXP: 750, xpForLevel: 1000, level: 5)

        HStack(spacing: 20) {
            StatRing(value: 80, maxValue: 100, icon: Theme.Icons.health, color: Theme.Colors.health)
            StatRing(value: 60, maxValue: 100, icon: Theme.Icons.energy, color: Theme.Colors.energy)
            LevelBadge(level: 12, isActive: true, size: 60)
        }
    }
    .padding()
    .background(Theme.Colors.background)
}
