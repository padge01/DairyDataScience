import SwiftUI

/// Main character sheet showing stats, skills, and progress
struct CharacterSheetView: View {
    @Environment(CharacterViewModel.self) private var viewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                if let character = viewModel.character {
                    VStack(spacing: 20) {
                        // Header with level and name
                        CharacterHeaderView(character: character)

                        // Vitality meters
                        VitalityMetersView(character: character)

                        // XP Progress
                        XPProgressView(
                            level: character.level,
                            progress: viewModel.xpProgress
                        )

                        // Skills overview
                        SkillsOverviewView(character: character)

                        // Recent activity
                        RecentActivityView(character: character)
                    }
                    .padding()
                } else {
                    ContentUnavailableView(
                        "No Character",
                        systemImage: "person.crop.circle.badge.questionmark",
                        description: Text("Create a character to begin your quest")
                    )
                }
            }
            .navigationTitle("Character Sheet")
            .refreshable {
                await viewModel.syncHealthData()
            }
        }
        .sheet(isPresented: .constant(viewModel.showLevelUp)) {
            if let levelUp = viewModel.recentLevelUp {
                LevelUpCelebrationView(levelUp: levelUp)
            }
        }
    }
}

// MARK: - Character Header

struct CharacterHeaderView: View {
    let character: Character

    var body: some View {
        VStack(spacing: 8) {
            // Avatar placeholder
            Circle()
                .fill(Constants.Colors.primary.gradient)
                .frame(width: 80, height: 80)
                .overlay {
                    Text(character.name.prefix(1).uppercased())
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                }

            Text(character.name)
                .font(.title2.bold())

            HStack(spacing: 4) {
                Text("Level \(character.level)")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("•")
                    .foregroundStyle(.tertiary)

                Text(character.status.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(statusColor)
            }
        }
    }

    var statusColor: Color {
        switch character.status {
        case .healthy: return .green
        case .tired: return .yellow
        case .exhausted, .drained: return .orange
        case .burnout: return .red
        }
    }
}

// MARK: - Vitality Meters

struct VitalityMetersView: View {
    let character: Character

    var body: some View {
        VStack(spacing: 12) {
            MeterView(
                label: "Health",
                value: character.currentHealth,
                max: character.maxHealth,
                color: Constants.Colors.health,
                icon: "heart.fill"
            )

            MeterView(
                label: "Energy",
                value: character.currentEnergy,
                max: character.maxEnergy,
                color: Constants.Colors.energy,
                icon: "bolt.fill"
            )

            if character.restDebt > 0 {
                HStack {
                    Image(systemName: "moon.zzz.fill")
                        .foregroundStyle(.orange)
                    Text("Rest Debt: \(character.restDebt)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius))
    }
}

struct MeterView: View {
    let label: String
    let value: Int
    let max: Int
    let color: Color
    let icon: String

    var progress: Double {
        guard max > 0 else { return 0 }
        return Double(value) / Double(max)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(label)
                    .font(.subheadline.bold())
                Spacer()
                Text("\(value)/\(max)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.2))

                    Capsule()
                        .fill(color.gradient)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - XP Progress

struct XPProgressView: View {
    let level: Int
    let progress: Double

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Level \(level)")
                    .font(.headline)
                Spacer()
                Text("Level \(level + 1)")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Constants.Colors.xp.opacity(0.2))

                    Capsule()
                        .fill(Constants.Colors.xp.gradient)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 12)

            Text("\(Int(progress * 100))% to next level")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius))
    }
}

// MARK: - Skills Overview

struct SkillsOverviewView: View {
    let character: Character

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Skills")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    SkillsListView(character: character)
                }
                .font(.subheadline)
            }

            // Top skills by level
            ForEach(topSkills, id: \.id) { skill in
                SkillRowView(skill: skill, isMajor: character.majorSkillIDs.contains(skill.skillID))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius))
    }

    var topSkills: [Skill] {
        character.skills
            .sorted { $0.currentLevel > $1.currentLevel }
            .prefix(5)
            .map { $0 }
    }
}

struct SkillRowView: View {
    let skill: Skill
    let isMajor: Bool

    var body: some View {
        HStack {
            Image(systemName: skill.domain.icon)
                .foregroundStyle(Constants.Colors.forDomain(skill.domain))
                .frame(width: 24)

            Text(skill.name)
                .font(.subheadline)

            if isMajor {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }

            Spacer()

            Text("Lv. \(skill.currentLevel)")
                .font(.subheadline.bold())
                .foregroundStyle(Constants.Colors.forDomain(skill.domain))
        }
    }
}

// MARK: - Recent Activity

struct RecentActivityView: View {
    let character: Character

    var recentActivities: [Activity] {
        character.activities
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
                NavigationLink("See All") {
                    ActivityHistoryView(character: character)
                }
                .font(.subheadline)
            }

            if recentActivities.isEmpty {
                Text("No activities yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ForEach(recentActivities, id: \.id) { activity in
                    ActivityRowView(activity: activity)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius))
    }
}

struct ActivityRowView: View {
    let activity: Activity

    var body: some View {
        HStack {
            Image(systemName: activity.source.icon)
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.displayDescription)
                    .font(.subheadline)
                    .lineLimit(1)

                Text(activity.timestamp.timeAgo)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if activity.totalXPAwarded > 0 {
                Text("+\(activity.totalXPAwarded) XP")
                    .font(.caption.bold())
                    .foregroundStyle(Constants.Colors.xp)
            }
        }
    }
}

// MARK: - Level Up Celebration

struct LevelUpCelebrationView: View {
    let levelUp: CharacterLevelUp
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(Constants.Colors.xp.gradient)

            Text("LEVEL UP!")
                .font(.largeTitle.bold())

            Text("Level \(levelUp.oldLevel) → Level \(levelUp.newLevel)")
                .font(.title2)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("Attribute Gains")
                    .font(.headline)

                HStack(spacing: 16) {
                    if levelUp.attributeGains.vitality > 0 {
                        AttributeGainView(name: "VIT", value: levelUp.attributeGains.vitality, color: .red)
                    }
                    if levelUp.attributeGains.willpower > 0 {
                        AttributeGainView(name: "WIL", value: levelUp.attributeGains.willpower, color: .blue)
                    }
                    if levelUp.attributeGains.charisma > 0 {
                        AttributeGainView(name: "CHA", value: levelUp.attributeGains.charisma, color: .purple)
                    }
                    if levelUp.attributeGains.expertise > 0 {
                        AttributeGainView(name: "EXP", value: levelUp.attributeGains.expertise, color: .orange)
                    }
                    if levelUp.attributeGains.balance > 0 {
                        AttributeGainView(name: "BAL", value: levelUp.attributeGains.balance, color: .green)
                    }
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

            Spacer()

            Button("Continue") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

struct AttributeGainView: View {
    let name: String
    let value: Int
    let color: Color

    var body: some View {
        VStack {
            Text("+\(value)")
                .font(.headline.bold())
                .foregroundStyle(color)
            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Placeholder Views

struct SkillsListView: View {
    let character: Character

    var body: some View {
        List {
            ForEach(SkillDomain.allCases, id: \.self) { domain in
                Section(domain.rawValue) {
                    ForEach(skillsForDomain(domain), id: \.id) { skill in
                        SkillDetailRow(skill: skill, character: character)
                    }
                }
            }
        }
        .navigationTitle("All Skills")
    }

    func skillsForDomain(_ domain: SkillDomain) -> [Skill] {
        character.skills.filter { $0.domain == domain }
    }
}

struct SkillDetailRow: View {
    let skill: Skill
    let character: Character

    var isMajor: Bool {
        character.majorSkillIDs.contains(skill.skillID)
    }

    var isMinor: Bool {
        character.minorSkillIDs.contains(skill.skillID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(skill.name)
                    .font(.headline)

                if isMajor {
                    Text("MAJOR")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.yellow.opacity(0.2))
                        .clipShape(Capsule())
                } else if isMinor {
                    Text("MINOR")
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.2))
                        .clipShape(Capsule())
                }

                Spacer()

                Text("Lv. \(skill.currentLevel)")
                    .font(.headline)
                    .foregroundStyle(Constants.Colors.forDomain(skill.domain))
            }

            ProgressView(value: skill.progressToNextLevel)
                .tint(Constants.Colors.forDomain(skill.domain))

            Text(skill.skillDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ActivityHistoryView: View {
    let character: Character

    var body: some View {
        List(character.activities.sorted { $0.timestamp > $1.timestamp }, id: \.id) { activity in
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.displayDescription)
                    .font(.subheadline)

                HStack {
                    Text(activity.timestamp.shortDate)
                    Text("•")
                    Text("+\(activity.totalXPAwarded) XP")
                        .foregroundStyle(Constants.Colors.xp)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Activity History")
    }
}

#Preview {
    CharacterSheetView()
}
