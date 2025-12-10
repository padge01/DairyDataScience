import SwiftUI

/// Activity logging view for manual check-ins
struct ActivityLogView: View {
    @Environment(CharacterViewModel.self) private var viewModel
    @State private var activityText = ""
    @State private var isLogging = false
    @State private var showingSuccess = false
    @State private var lastResult: [SkillGain] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Quick log section
                QuickLogSection(
                    text: $activityText,
                    isLogging: isLogging,
                    onLog: logActivity
                )

                // Recent XP gains
                if showingSuccess && !lastResult.isEmpty {
                    XPGainResultView(gains: lastResult)
                        .transition(.scale.combined(with: .opacity))
                }

                // Quick actions
                QuickActionsView(onAction: { action in
                    activityText = action
                })

                // Today's summary
                if let character = viewModel.character {
                    TodaySummaryView(character: character)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Log Activity")
        }
    }

    func logActivity() {
        guard !activityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isLogging = true

        Task {
            await viewModel.logActivity(activityText)

            await MainActor.run {
                isLogging = false
                lastResult = viewModel.recentSkillLevelUps.isEmpty ? [] :
                    viewModel.character?.activities.last?.skillGains ?? []

                withAnimation {
                    showingSuccess = true
                }

                activityText = ""

                // Hide success after delay
                Task {
                    try? await Task.sleep(for: .seconds(3))
                    await MainActor.run {
                        withAnimation {
                            showingSuccess = false
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Quick Log Section

struct QuickLogSection: View {
    @Binding var text: String
    let isLogging: Bool
    let onLog: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What did you do?")
                .font(.headline)

            TextField("e.g., 90 min BJJ session, worked on guard passing", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(2...4)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button(action: onLog) {
                HStack {
                    if isLogging {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemName: "plus.circle.fill")
                        Text("Log Activity")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(canLog ? Constants.Colors.primary : Color.secondary)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canLog)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius))
    }

    var canLog: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLogging
    }
}

// MARK: - XP Gain Result

struct XPGainResultView: View {
    let gains: [SkillGain]

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundStyle(.green)

            Text("Activity Logged!")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(gains, id: \.id) { gain in
                    VStack {
                        Text("+\(gain.amount)")
                            .font(.headline.bold())
                            .foregroundStyle(Constants.Colors.xp)
                        Text(gain.skillID.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius))
    }
}

// MARK: - Quick Actions

struct QuickActionsView: View {
    let onAction: (String) -> Void

    let quickActions = [
        ("figure.run", "Workout"),
        ("book.fill", "Reading"),
        ("brain.head.profile", "Deep Work"),
        ("bed.double.fill", "Good Sleep"),
        ("figure.yoga", "Stretching"),
        ("person.2.fill", "Social Time")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Log")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(quickActions, id: \.1) { icon, label in
                    Button {
                        onAction(label)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: icon)
                                .font(.title2)
                            Text(label)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius))
    }
}

// MARK: - Today's Summary

struct TodaySummaryView: View {
    let character: Character

    var todaysActivities: [Activity] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return character.activities.filter {
            calendar.startOfDay(for: $0.timestamp) == today
        }
    }

    var todaysXP: Int {
        todaysActivities.reduce(0) { $0 + $1.totalXPAwarded }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                Spacer()
                Text("\(todaysActivities.count) activities")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 20) {
                StatBox(
                    label: "XP Earned",
                    value: "\(todaysXP)",
                    icon: "sparkles",
                    color: Constants.Colors.xp
                )

                StatBox(
                    label: "Skills Trained",
                    value: "\(uniqueSkillsTrained)",
                    icon: "chart.bar.fill",
                    color: Constants.Colors.primary
                )

                StatBox(
                    label: "Quests Done",
                    value: "\(questsCompleted)",
                    icon: "checkmark.circle.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius))
    }

    var uniqueSkillsTrained: Int {
        Set(todaysActivities.flatMap { $0.skillGains.map { $0.skillID } }).count
    }

    var questsCompleted: Int {
        character.quests.filter { $0.isCompletedToday }.count
    }
}

struct StatBox: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(value)
                .font(.headline.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ActivityLogView()
}
