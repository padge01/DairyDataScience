import SwiftUI

/// Main character sheet showing stats, skills, and progress
struct CharacterSheetView: View {
    @Environment(CharacterViewModel.self) private var viewModel
    @State private var showingLevelUp = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    if let character = viewModel.character {
                        VStack(spacing: Theme.Spacing.lg) {
                            // Character header with avatar
                            CharacterHeader(character: character)
                                .padding(.top, Theme.Spacing.md)

                            // XP Progress bar
                            XPBar(
                                currentXP: character.totalXP % 1000,
                                xpForLevel: 1000,
                                level: character.level
                            )
                            .padding(.horizontal, Theme.Spacing.md)

                            // Vitality panel
                            VitalityPanel(character: character)
                                .padding(.horizontal, Theme.Spacing.md)

                            // Skills section
                            SkillsSectionView(character: character)
                                .padding(.horizontal, Theme.Spacing.md)

                            // Attributes panel
                            AttributesPanel(character: character)
                                .padding(.horizontal, Theme.Spacing.md)

                            // Recent activity
                            RecentActivitySection(character: character)
                                .padding(.horizontal, Theme.Spacing.md)

                            Spacer(minLength: Theme.Spacing.xxl)
                        }
                    } else {
                        EmptyCharacterView()
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Character")
                        .font(Theme.Typography.headlineSmall)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
            }
            .refreshable {
                await viewModel.syncHealthData()
            }
        }
        .sheet(isPresented: $showingLevelUp) {
            if let levelUp = viewModel.recentLevelUp {
                LevelUpCelebration(levelUp: levelUp)
            }
        }
        .onChange(of: viewModel.showLevelUp) { _, newValue in
            showingLevelUp = newValue
        }
    }
}

// MARK: - Empty State

struct EmptyCharacterView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 80))
                .foregroundStyle(Theme.Colors.textTertiary)

            Text("No Character")
                .font(Theme.Typography.headlineLarge)
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Create a character to begin your quest")
                .font(Theme.Typography.bodyMedium)
                .foregroundStyle(Theme.Colors.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Skills Section

struct SkillsSectionView: View {
    let character: Character

    var topSkills: [Skill] {
        character.skills
            .sorted { $0.currentLevel > $1.currentLevel }
            .prefix(4)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(Theme.Colors.primaryFallback)
                    Text("Skills")
                        .font(Theme.Typography.headlineSmall)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Spacer()

                NavigationLink {
                    SkillsListViewPolished(character: character)
                } label: {
                    HStack(spacing: Theme.Spacing.xxs) {
                        Text("See All")
                            .font(Theme.Typography.labelMedium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Theme.Colors.primaryFallback)
                }
            }

            // Top skills grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.sm) {
                ForEach(topSkills, id: \.id) { skill in
                    CompactSkillCard(
                        skill: skill,
                        isMajor: character.majorSkillIDs.contains(skill.skillID)
                    )
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }
}

/// Compact skill card for grid display
struct CompactSkillCard: View {
    let skill: Skill
    var isMajor: Bool = false

    var color: Color {
        Theme.Colors.forDomain(skill.domain)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            HStack {
                Image(systemName: skill.domain.icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)

                Spacer()

                if isMajor {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.Colors.xp)
                }

                Text("Lv.\(skill.currentLevel)")
                    .font(Theme.Typography.statSmall)
                    .foregroundStyle(color)
            }

            Text(skill.name)
                .font(Theme.Typography.labelMedium)
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)

            SkillProgressBar(progress: skill.progressToNextLevel, color: color, height: 3)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
    }
}

// MARK: - Recent Activity Section

struct RecentActivitySection: View {
    let character: Character

    var recentActivities: [Activity] {
        character.activities
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            // Header
            HStack {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(Theme.Colors.primaryFallback)
                    Text("Recent Activity")
                        .font(Theme.Typography.headlineSmall)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }

                Spacer()

                NavigationLink {
                    ActivityHistoryViewPolished(character: character)
                } label: {
                    HStack(spacing: Theme.Spacing.xxs) {
                        Text("See All")
                            .font(Theme.Typography.labelMedium)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(Theme.Colors.primaryFallback)
                }
            }

            if recentActivities.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: Theme.Spacing.xs) {
                        Image(systemName: "tray")
                            .font(.system(size: 32))
                            .foregroundStyle(Theme.Colors.textTertiary)
                        Text("No activities yet")
                            .font(Theme.Typography.bodySmall)
                            .foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .padding(Theme.Spacing.lg)
                    Spacer()
                }
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(recentActivities, id: \.id) { activity in
                        CompactActivityRow(activity: activity)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
    }
}

/// Compact activity row
struct CompactActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ActivitySourceBadge(source: activity.source)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.displayDescription)
                    .font(Theme.Typography.labelMedium)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .lineLimit(1)

                Text(activity.timestamp.timeAgo)
                    .font(Theme.Typography.bodySmall)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }

            Spacer()

            if activity.totalXPAwarded > 0 {
                Text("+\(activity.totalXPAwarded)")
                    .font(Theme.Typography.labelSmall)
                    .foregroundStyle(Theme.Colors.xp)
                    .padding(.horizontal, Theme.Spacing.xs)
                    .padding(.vertical, Theme.Spacing.xxxs)
                    .background(Theme.Colors.xp.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
    }
}

// MARK: - Polished List Views

struct SkillsListViewPolished: View {
    let character: Character

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.md) {
                    ForEach(SkillDomain.allCases, id: \.self) { domain in
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            DomainHeader(
                                domain: domain,
                                skillCount: skillsForDomain(domain).count,
                                averageLevel: averageLevel(for: domain)
                            )

                            ForEach(skillsForDomain(domain), id: \.id) { skill in
                                SkillCard(
                                    skill: skill,
                                    isMajor: character.majorSkillIDs.contains(skill.skillID),
                                    isMinor: character.minorSkillIDs.contains(skill.skillID)
                                )
                            }
                        }
                        .padding(Theme.Spacing.md)
                        .background(Theme.Colors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
        .navigationTitle("All Skills")
        .navigationBarTitleDisplayMode(.inline)
    }

    func skillsForDomain(_ domain: SkillDomain) -> [Skill] {
        character.skills.filter { $0.domain == domain }
    }

    func averageLevel(for domain: SkillDomain) -> Int {
        let skills = skillsForDomain(domain)
        guard !skills.isEmpty else { return 0 }
        return skills.reduce(0) { $0 + $1.currentLevel } / skills.count
    }
}

struct ActivityHistoryViewPolished: View {
    let character: Character

    var groupedActivities: [(date: Date, activities: [Activity])] {
        let sorted = character.activities.sorted { $0.timestamp > $1.timestamp }
        let grouped = Dictionary(grouping: sorted) { activity in
            Calendar.current.startOfDay(for: activity.timestamp)
        }
        return grouped.map { ($0.key, $0.value) }.sorted { $0.date > $1.date }
    }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            ScrollView {
                LazyVStack(spacing: Theme.Spacing.lg) {
                    ForEach(groupedActivities, id: \.date) { group in
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text(group.date.formatted(date: .abbreviated, time: .omitted))
                                .font(Theme.Typography.labelMedium)
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .padding(.leading, Theme.Spacing.xs)

                            VStack(spacing: Theme.Spacing.xs) {
                                ForEach(group.activities, id: \.id) { activity in
                                    ActivityCard(activity: activity)
                                }
                            }
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
        }
        .navigationTitle("Activity History")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Level Up Celebration

struct LevelUpCelebration: View {
    let levelUp: CharacterLevelUp
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var showButtons = false

    var body: some View {
        ZStack {
            // Background
            Theme.Colors.background.ignoresSafeArea()

            // Animated particles
            LevelUpParticles()

            VStack(spacing: Theme.Spacing.xl) {
                Spacer()

                // Level up badge
                if showContent {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Glowing icon
                        ZStack {
                            Circle()
                                .fill(Theme.Colors.xp.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .blur(radius: 20)

                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 80))
                                .foregroundStyle(Theme.Colors.goldGradient)
                                .shadow(color: Theme.Colors.xpGlow, radius: 20)
                        }
                        .transition(.scale.combined(with: .opacity))

                        Text("LEVEL UP!")
                            .font(Theme.Typography.displayMedium)
                            .foregroundStyle(Theme.Colors.goldGradient)
                            .shadow(color: Theme.Colors.xpGlow.opacity(0.5), radius: 10)

                        // Level change
                        HStack(spacing: Theme.Spacing.md) {
                            LevelBadge(level: levelUp.oldLevel, isActive: false, size: 50)
                            Image(systemName: "arrow.right")
                                .font(.title2)
                                .foregroundStyle(Theme.Colors.textSecondary)
                            LevelBadge(level: levelUp.newLevel, isActive: true, size: 60)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                // Attribute gains
                if showContent {
                    VStack(spacing: Theme.Spacing.md) {
                        Text("Attribute Gains")
                            .font(Theme.Typography.headlineSmall)
                            .foregroundStyle(Theme.Colors.textSecondary)

                        HStack(spacing: Theme.Spacing.lg) {
                            if levelUp.attributeGains.vitality > 0 {
                                AttributeGainBadge(name: "Vitality", value: levelUp.attributeGains.vitality, color: Theme.Colors.health)
                            }
                            if levelUp.attributeGains.willpower > 0 {
                                AttributeGainBadge(name: "Willpower", value: levelUp.attributeGains.willpower, color: Theme.Colors.energy)
                            }
                            if levelUp.attributeGains.charisma > 0 {
                                AttributeGainBadge(name: "Charisma", value: levelUp.attributeGains.charisma, color: Theme.Colors.social)
                            }
                            if levelUp.attributeGains.expertise > 0 {
                                AttributeGainBadge(name: "Expertise", value: levelUp.attributeGains.expertise, color: Theme.Colors.professional)
                            }
                            if levelUp.attributeGains.balance > 0 {
                                AttributeGainBadge(name: "Balance", value: levelUp.attributeGains.balance, color: Theme.Colors.maintenance)
                            }
                        }
                    }
                    .padding(Theme.Spacing.lg)
                    .background(Theme.Colors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.lg))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()

                // Continue button
                if showButtons {
                    Button {
                        dismiss()
                    } label: {
                        Text("Continue")
                            .font(Theme.Typography.labelLarge)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.primaryGradient)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md))
                    }
                    .padding(.horizontal, Theme.Spacing.xl)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .onAppear {
            // Staggered animations
            withAnimation(Theme.Animation.levelUp.delay(0.2)) {
                showContent = true
            }
            withAnimation(Theme.Animation.standard.delay(0.8)) {
                showButtons = true
            }
        }
    }
}

struct AttributeGainBadge: View {
    let name: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: Theme.Spacing.xxs) {
            Text("+\(value)")
                .font(Theme.Typography.statMedium)
                .foregroundStyle(color)

            Text(name.prefix(3).uppercased())
                .font(Theme.Typography.labelSmall)
                .foregroundStyle(Theme.Colors.textTertiary)
        }
    }
}

struct LevelUpParticles: View {
    @State private var particles: [(id: UUID, x: CGFloat, y: CGFloat, delay: Double)] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles, id: \.id) { particle in
                    Image(systemName: "sparkle")
                        .font(.system(size: CGFloat.random(in: 8...16)))
                        .foregroundStyle(Theme.Colors.xp.opacity(0.6))
                        .position(
                            x: particle.x * geo.size.width,
                            y: particle.y * geo.size.height
                        )
                }
            }
        }
        .onAppear {
            generateParticles()
        }
    }

    private func generateParticles() {
        for i in 0..<20 {
            let particle = (
                id: UUID(),
                x: CGFloat.random(in: 0...1),
                y: CGFloat.random(in: 0...1),
                delay: Double(i) * 0.1
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + particle.delay) {
                withAnimation(.easeOut(duration: 1.5)) {
                    particles.append(particle)
                }
            }
        }
    }
}

#Preview {
    CharacterSheetView()
}
