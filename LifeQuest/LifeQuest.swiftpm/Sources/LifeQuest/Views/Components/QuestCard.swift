import SwiftUI

/// Polished quest card with streak info and completion state
struct QuestCard: View {
    let quest: Quest
    var onComplete: (() -> Void)? = nil

    @State private var isCompleting = false
    @State private var showConfetti = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Completion button
            CompletionButton(
                isCompleted: quest.isCompletedToday,
                isLoading: isCompleting,
                onTap: handleComplete
            )

            // Quest content
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                // Title row
                HStack(spacing: Theme.Spacing.xs) {
                    Text(quest.name)
                        .font(Theme.Typography.labelLarge)
                        .foregroundStyle(
                            quest.isCompletedToday
                                ? Theme.Colors.textTertiary
                                : Theme.Colors.textPrimary
                        )
                        .strikethrough(quest.isCompletedToday)

                    if quest.autoCompleteType != nil {
                        Image(systemName: Theme.Icons.auto)
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.health)
                    }

                    Spacer()

                    XPReward(amount: quest.effectiveXP, multiplier: quest.streakMultiplier)
                }

                // Description
                Text(quest.questDescription)
                    .font(Theme.Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textTertiary)
                    .lineLimit(1)

                // Streak info
                if quest.currentStreak > 0 || quest.isCompletedToday {
                    StreakBadge(
                        days: quest.currentStreak,
                        tier: quest.streakTier
                    )
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(
            quest.isCompletedToday
                ? Theme.Colors.success.opacity(0.08)
                : Theme.Colors.surfaceElevated
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.lg)
                .stroke(
                    quest.isCompletedToday
                        ? Theme.Colors.success.opacity(0.3)
                        : Theme.Colors.surfaceHighlight,
                    lineWidth: 1
                )
        )
        .overlay {
            if showConfetti {
                ConfettiOverlay()
            }
        }
    }

    private func handleComplete() {
        guard !quest.isCompletedToday else { return }

        isCompleting = true

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()

        // Animate completion
        withAnimation(Theme.Animation.spring) {
            onComplete?()
            showConfetti = true
        }

        isCompleting = false

        // Hide confetti
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showConfetti = false
        }
    }
}

/// Animated completion checkbox
struct CompletionButton: View {
    let isCompleted: Bool
    var isLoading: Bool = false
    var onTap: (() -> Void)?

    @State private var scale: CGFloat = 1.0

    var body: some View {
        Button {
            if !isCompleted {
                // Bounce animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.3
                }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) {
                    scale = 1.0
                }
                onTap?()
            }
        } label: {
            ZStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Circle()
                        .stroke(
                            isCompleted ? Theme.Colors.success : Theme.Colors.textTertiary,
                            lineWidth: 2
                        )
                        .frame(width: 28, height: 28)

                    if isCompleted {
                        Circle()
                            .fill(Theme.Colors.success)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .scaleEffect(scale)
        }
        .buttonStyle(.plain)
        .disabled(isCompleted)
    }
}

/// XP reward display with multiplier
struct XPReward: View {
    let amount: Int
    var multiplier: Double = 1.0

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Text("+\(amount)")
                .font(Theme.Typography.labelMedium)
                .foregroundStyle(Theme.Colors.xp)

            Text("XP")
                .font(Theme.Typography.labelSmall)
                .foregroundStyle(Theme.Colors.xp.opacity(0.7))

            if multiplier > 1.0 {
                Text("(\(String(format: "%.1fx", multiplier)))")
                    .font(Theme.Typography.labelSmall)
                    .foregroundStyle(Theme.Colors.warning)
            }
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, Theme.Spacing.xxs)
        .background(Theme.Colors.xp.opacity(0.1))
        .clipShape(Capsule())
    }
}

/// Streak badge with fire icon
struct StreakBadge: View {
    let days: Int
    let tier: StreakTier

    var color: Color {
        Theme.Colors.forStreak(tier)
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Image(systemName: Theme.Icons.streak)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)

            Text("\(days) day streak")
                .font(Theme.Typography.labelSmall)
                .foregroundStyle(color)
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, Theme.Spacing.xxxs)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

/// Confetti celebration overlay
struct ConfettiOverlay: View {
    @State private var particles: [ConfettiParticle] = []

    struct ConfettiParticle: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        let color: Color
        let rotation: Double
        let scale: CGFloat
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(color: particle.color)
                        .scaleEffect(particle.scale)
                        .rotationEffect(.degrees(particle.rotation))
                        .position(x: particle.x * geo.size.width, y: particle.y * geo.size.height)
                }
            }
        }
        .onAppear {
            generateParticles()
        }
    }

    private func generateParticles() {
        let colors: [Color] = [
            Theme.Colors.success,
            Theme.Colors.xp,
            Theme.Colors.primaryFallback,
            Theme.Colors.info
        ]

        for _ in 0..<15 {
            let particle = ConfettiParticle(
                x: CGFloat.random(in: 0.2...0.8),
                y: CGFloat.random(in: -0.2...0.5),
                color: colors.randomElement()!,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.0)
            )

            withAnimation(.easeOut(duration: 0.5)) {
                particles.append(particle)
            }
        }

        // Animate particles falling
        withAnimation(.easeIn(duration: 1.0).delay(0.3)) {
            for i in particles.indices {
                particles[i].y += 1.5
            }
        }
    }
}

struct ConfettiPiece: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 8, height: 8)
    }
}

/// Weekly quest progress card
struct WeeklyQuestCard: View {
    let quest: Quest

    var progressPercentage: Double {
        guard quest.targetCount > 0 else { return 0 }
        return Double(quest.currentPeriodCount) / Double(quest.targetCount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(quest.name)
                        .font(Theme.Typography.labelLarge)
                        .foregroundStyle(Theme.Colors.textPrimary)

                    Text(quest.questDescription)
                        .font(Theme.Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                Spacer()

                XPReward(amount: quest.effectiveXP, multiplier: quest.streakMultiplier)
            }

            // Progress bar
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.Colors.primaryFallback.opacity(0.15))

                        Capsule()
                            .fill(Theme.Colors.primaryGradient)
                            .frame(width: geo.size.width * progressPercentage)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("\(quest.currentPeriodCount) / \(quest.targetCount) completed")
                        .font(Theme.Typography.labelSmall)
                        .foregroundStyle(Theme.Colors.textSecondary)

                    Spacer()

                    if quest.currentStreak > 0 {
                        StreakBadge(days: quest.currentStreak, tier: quest.streakTier)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }
}

#Preview {
    VStack(spacing: 16) {
        QuestCard(
            quest: {
                let q = Quest(name: "Morning Movement", description: "10 min of intentional movement", type: .daily, baseXP: 25)
                q.currentStreak = 7
                return q
            }()
        )

        QuestCard(
            quest: {
                let q = Quest(name: "Daily Steps", description: "Walk 10,000 steps", type: .daily, baseXP: 30)
                q.isCompletedToday = true
                q.currentStreak = 15
                return q
            }()
        )

        WeeklyQuestCard(
            quest: {
                let q = Quest(name: "Train 3x", description: "Complete 3 workout sessions", type: .weekly, baseXP: 100)
                q.targetCount = 3
                q.currentPeriodCount = 2
                q.currentStreak = 4
                return q
            }()
        )
    }
    .padding()
    .background(Theme.Colors.background)
}
