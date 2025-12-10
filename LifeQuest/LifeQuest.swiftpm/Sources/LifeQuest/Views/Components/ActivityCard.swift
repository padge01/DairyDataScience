import SwiftUI

/// Activity log card showing interpreted activity with XP gains
struct ActivityCard: View {
    let activity: Activity
    var isExpanded: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            // Header
            HStack(spacing: Theme.Spacing.sm) {
                // Source icon
                ActivitySourceBadge(source: activity.source)

                VStack(alignment: .leading, spacing: Theme.Spacing.xxxs) {
                    Text(activity.displayDescription)
                        .font(Theme.Typography.labelMedium)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .lineLimit(isExpanded ? nil : 2)

                    Text(activity.timestamp.timeAgo)
                        .font(Theme.Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }

                Spacer()

                // Total XP
                if activity.totalXPAwarded > 0 {
                    TotalXPBadge(amount: activity.totalXPAwarded)
                }
            }

            // Skill gains breakdown
            if !activity.skillGains.isEmpty {
                SkillGainsRow(gains: activity.skillGains)
            }

            // AI Notes (if available and expanded)
            if isExpanded, let notes = activity.aiNotes, !notes.isEmpty {
                HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                    Image(systemName: Theme.Icons.insight)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.primaryFallback)

                    Text(notes)
                        .font(Theme.Typography.bodySmall)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .italic()
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.primaryFallback.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm))
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }
}

/// Badge showing activity source
struct ActivitySourceBadge: View {
    let source: ActivitySource

    var icon: String {
        switch source {
        case .manual: return "pencil.circle.fill"
        case .healthKit: return "heart.circle.fill"
        case .questComplete: return "checkmark.circle.fill"
        case .aiSuggested: return "sparkles"
        }
    }

    var color: Color {
        switch source {
        case .manual: return Theme.Colors.info
        case .healthKit: return Theme.Colors.health
        case .questComplete: return Theme.Colors.success
        case .aiSuggested: return Theme.Colors.primaryFallback
        }
    }

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 24))
            .foregroundStyle(color)
    }
}

/// Total XP badge
struct TotalXPBadge: View {
    let amount: Int

    @State private var animatedAmount: Int = 0

    var body: some View {
        HStack(spacing: 2) {
            Text("+\(animatedAmount)")
                .font(Theme.Typography.statSmall)
                .foregroundStyle(Theme.Colors.xp)

            Image(systemName: "sparkle")
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.xp)
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, Theme.Spacing.xxs)
        .background(Theme.Colors.xp.opacity(0.15))
        .clipShape(Capsule())
        .onAppear {
            // Animate counting up
            animateCount()
        }
    }

    private func animateCount() {
        let duration: Double = 0.5
        let steps = 10
        let stepDuration = duration / Double(steps)
        let increment = amount / steps

        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                if i == steps - 1 {
                    animatedAmount = amount
                } else {
                    animatedAmount = increment * (i + 1)
                }
            }
        }
    }
}

/// Horizontal row of skill gains
struct SkillGainsRow: View {
    let gains: [SkillGain]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.xs) {
                ForEach(gains, id: \.id) { gain in
                    SkillGainChip(gain: gain)
                }
            }
        }
    }
}

/// Individual skill gain chip
struct SkillGainChip: View {
    let gain: SkillGain

    var skillName: String {
        gain.skillID
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }

    var domain: SkillDomain {
        // Map skill ID to domain
        if ["strength", "endurance", "mobility", "recovery"].contains(gain.skillID) {
            return .physical
        } else if ["focus", "learning", "problem_solving", "creativity"].contains(gain.skillID) {
            return .mental
        } else if ["communication", "leadership", "empathy", "networking"].contains(gain.skillID) {
            return .social
        } else if ["sleep", "nutrition", "stress_management", "finance"].contains(gain.skillID) {
            return .maintenance
        }
        return .professional
    }

    var color: Color {
        Theme.Colors.forDomain(domain)
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.xxs) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(skillName)
                .font(Theme.Typography.labelSmall)
                .foregroundStyle(Theme.Colors.textSecondary)

            Text("+\(gain.amount)")
                .font(Theme.Typography.labelSmall)
                .foregroundStyle(color)
        }
        .padding(.horizontal, Theme.Spacing.xs)
        .padding(.vertical, Theme.Spacing.xxs)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

/// Activity input field with suggestions
struct ActivityInputField: View {
    @Binding var text: String
    var placeholder: String = "What did you do?"
    var isLoading: Bool = false
    var onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.sm) {
                // Text field
                TextField(placeholder, text: $text, axis: .vertical)
                    .font(Theme.Typography.bodyLarge)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1...4)
                    .focused($isFocused)
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.lg)
                            .stroke(
                                isFocused ? Theme.Colors.primaryFallback : Theme.Colors.surfaceHighlight,
                                lineWidth: isFocused ? 2 : 1
                            )
                    )

                // Submit button
                Button {
                    onSubmit()
                    isFocused = false
                } label: {
                    ZStack {
                        Circle()
                            .fill(canSubmit ? Theme.Colors.primaryGradient : LinearGradient(colors: [Theme.Colors.textTertiary], startPoint: .top, endPoint: .bottom))
                            .frame(width: 48, height: 48)

                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .disabled(!canSubmit)
            }
        }
    }

    var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
}

/// Quick action button for common activities
struct QuickActionButton: View {
    let icon: String
    let label: String
    var color: Color = Theme.Colors.primaryFallback
    var onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundStyle(color)
                }

                Text(label)
                    .font(Theme.Typography.labelSmall)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
        }
        .buttonStyle(PressEffectButtonStyle())
    }
}

/// Grid of quick actions
struct QuickActionsGrid: View {
    let onAction: (String) -> Void

    let actions = [
        ("figure.run", "Workout", Theme.Colors.physical),
        ("book.fill", "Reading", Theme.Colors.mental),
        ("brain.head.profile", "Deep Work", Theme.Colors.mental),
        ("bed.double.fill", "Sleep", Theme.Colors.maintenance),
        ("figure.yoga", "Stretching", Theme.Colors.physical),
        ("person.2.fill", "Social", Theme.Colors.social)
    ]

    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: Theme.Spacing.md) {
            ForEach(actions, id: \.1) { icon, label, color in
                QuickActionButton(icon: icon, label: label, color: color) {
                    onAction(label)
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 16) {
            ActivityCard(
                activity: {
                    let a = Activity(rawInput: "90 minute BJJ session, worked on guard retention and sweeps")
                    a.interpretation = "Brazilian Jiu-Jitsu training session focused on guard work"
                    a.skillGains = [
                        SkillGain(skillID: "endurance", amount: 35),
                        SkillGain(skillID: "mobility", amount: 20),
                        SkillGain(skillID: "focus", amount: 15)
                    ]
                    a.aiNotes = "Great training duration! Guard work builds both physical and mental resilience."
                    return a
                }(),
                isExpanded: true
            )

            ActivityInputField(text: .constant(""), onSubmit: {})

            QuickActionsGrid(onAction: { _ in })
        }
        .padding()
    }
    .background(Theme.Colors.background)
}
