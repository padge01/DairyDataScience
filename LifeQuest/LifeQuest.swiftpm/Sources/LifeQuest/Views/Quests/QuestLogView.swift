import SwiftUI

/// Quest log showing daily and weekly tasks
struct QuestLogView: View {
    @Environment(CharacterViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                if let character = viewModel.character {
                    VStack(spacing: 20) {
                        // Daily Quests
                        QuestSectionView(
                            title: "Daily Quests",
                            icon: "sun.max.fill",
                            quests: dailyQuests(for: character),
                            onComplete: { quest in
                                viewModel.completeQuest(quest)
                            }
                        )

                        // Weekly Quests
                        QuestSectionView(
                            title: "Weekly Quests",
                            icon: "calendar",
                            quests: weeklyQuests(for: character),
                            onComplete: { quest in
                                viewModel.completeQuest(quest)
                            }
                        )

                        // Suggested Quests
                        SuggestedQuestsView()
                    }
                    .padding()
                } else {
                    ContentUnavailableView(
                        "No Character",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Create a character to see quests")
                    )
                }
            }
            .navigationTitle("Quest Log")
        }
    }

    func dailyQuests(for character: Character) -> [Quest] {
        character.quests.filter {
            $0.questType == .daily && $0.isActive
        }
    }

    func weeklyQuests(for character: Character) -> [Quest] {
        character.quests.filter {
            $0.questType == .weekly && $0.isActive
        }
    }
}

// MARK: - Quest Section

struct QuestSectionView: View {
    let title: String
    let icon: String
    let quests: [Quest]
    let onComplete: (Quest) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(Constants.Colors.primary)
                Text(title)
                    .font(.headline)
                Spacer()
                Text("\(completedCount)/\(quests.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if quests.isEmpty {
                Text("No quests available")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(quests, id: \.id) { quest in
                    QuestCardView(quest: quest, onComplete: {
                        onComplete(quest)
                    })
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius))
    }

    var completedCount: Int {
        quests.filter { $0.isCompletedToday }.count
    }
}

// MARK: - Quest Card

struct QuestCardView: View {
    let quest: Quest
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Completion button
            Button {
                if !quest.isCompletedToday {
                    onComplete()
                }
            } label: {
                Image(systemName: quest.isCompletedToday ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(quest.isCompletedToday ? .green : .secondary)
            }
            .buttonStyle(.plain)

            // Quest details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(quest.name)
                        .font(.subheadline.bold())
                        .strikethrough(quest.isCompletedToday)

                    if quest.autoCompleteType != nil {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(.pink)
                }
                }

                Text(quest.questDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                // Streak and XP info
                HStack(spacing: 8) {
                    if quest.currentStreak > 0 {
                        Label("\(quest.currentStreak) day streak", systemImage: "flame.fill")
                            .font(.caption2)
                            .foregroundStyle(Constants.Colors.forStreakTier(quest.streakTier))
                    }

                    Spacer()

                    Text("+\(quest.effectiveXP) XP")
                        .font(.caption.bold())
                        .foregroundStyle(Constants.Colors.xp)

                    if quest.streakMultiplier > 1.0 {
                        Text("(\(String(format: "%.2fx", quest.streakMultiplier)))")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding()
        .background(quest.isCompletedToday ? Color.green.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Suggested Quests

struct SuggestedQuestsView: View {
    @State private var showingSuggestions = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(.yellow)
                Text("Suggested Quests")
                    .font(.headline)
                Spacer()
                Button {
                    showingSuggestions.toggle()
                } label: {
                    Image(systemName: showingSuggestions ? "chevron.up" : "chevron.down")
                }
            }

            if showingSuggestions {
                Text("Based on your skill gaps, consider adding these quests:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Placeholder suggestions
                SuggestionRow(
                    name: "Morning Stretch",
                    description: "5 minutes of stretching after waking",
                    skill: "Mobility",
                    xp: 15
                )

                SuggestionRow(
                    name: "Reading Block",
                    description: "30 minutes of focused reading",
                    skill: "Learning",
                    xp: 25
                )
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius))
    }
}

struct SuggestionRow: View {
    let name: String
    let description: String
    let skill: String
    let xp: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(skill)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("+\(xp) XP")
                    .font(.caption.bold())
                    .foregroundStyle(Constants.Colors.xp)
            }

            Button {
                // Add quest
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Constants.Colors.primary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    QuestLogView()
}
