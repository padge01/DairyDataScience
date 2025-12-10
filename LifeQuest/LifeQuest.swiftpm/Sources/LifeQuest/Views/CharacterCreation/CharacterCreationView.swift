import SwiftUI

/// Character creation flow for new users
struct CharacterCreationView: View {
    @Environment(CharacterViewModel.self) private var viewModel
    @State private var currentStep = 0
    @State private var characterName = ""
    @State private var selectedMajorSkills: Set<String> = []
    @State private var selectedMinorSkills: Set<String> = []

    let steps = ["Name", "Major Skills", "Minor Skills", "Confirm"]

    var body: some View {
        NavigationStack {
            VStack {
                // Progress indicator
                ProgressBar(currentStep: currentStep, totalSteps: steps.count)
                    .padding()

                // Step content
                TabView(selection: $currentStep) {
                    NameStepView(name: $characterName)
                        .tag(0)

                    MajorSkillsStepView(selected: $selectedMajorSkills)
                        .tag(1)

                    MinorSkillsStepView(
                        selected: $selectedMinorSkills,
                        majorSkills: selectedMajorSkills
                    )
                        .tag(2)

                    ConfirmationStepView(
                        name: characterName,
                        majorSkills: selectedMajorSkills,
                        minorSkills: selectedMinorSkills
                    )
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation {
                                currentStep -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    if currentStep < steps.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canProceed)
                    } else {
                        Button("Begin Quest") {
                            createCharacter()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canProceed)
                    }
                }
                .padding()
            }
            .navigationTitle("Create Character")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    var canProceed: Bool {
        switch currentStep {
        case 0: return !characterName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 1: return selectedMajorSkills.count == 5
        case 2: return selectedMinorSkills.count == 5
        case 3: return true
        default: return false
        }
    }

    func createCharacter() {
        viewModel.createCharacter(
            name: characterName,
            majorSkills: Array(selectedMajorSkills),
            minorSkills: Array(selectedMinorSkills)
        )
    }
}

// MARK: - Progress Bar

struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Constants.Colors.primary : Color.secondary.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }
}

// MARK: - Name Step

struct NameStepView: View {
    @Binding var name: String

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(Constants.Colors.primary.gradient)

            Text("What's your name?")
                .font(.title.bold())

            Text("This is how your coach will address you.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            TextField("Enter your name", text: $name)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

// MARK: - Major Skills Step

struct MajorSkillsStepView: View {
    @Binding var selected: Set<String>

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Choose 5 Major Skills")
                    .font(.title2.bold())

                Text("These are your primary focus areas. They start at level 10 and contribute fully to character leveling.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("\(selected.count)/5 selected")
                    .font(.caption)
                    .foregroundStyle(selected.count == 5 ? .green : .orange)
            }
            .padding()

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(SkillDomain.allCases, id: \.self) { domain in
                        SkillDomainSection(
                            domain: domain,
                            selected: $selected,
                            maxSelections: 5,
                            excluded: []
                        )
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Minor Skills Step

struct MinorSkillsStepView: View {
    @Binding var selected: Set<String>
    let majorSkills: Set<String>

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Choose 5 Minor Skills")
                    .font(.title2.bold())

                Text("Secondary skills that start at level 5 and contribute 50% to character leveling.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Text("\(selected.count)/5 selected")
                    .font(.caption)
                    .foregroundStyle(selected.count == 5 ? .green : .orange)
            }
            .padding()

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(SkillDomain.allCases, id: \.self) { domain in
                        SkillDomainSection(
                            domain: domain,
                            selected: $selected,
                            maxSelections: 5,
                            excluded: majorSkills
                        )
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Skill Domain Section

struct SkillDomainSection: View {
    let domain: SkillDomain
    @Binding var selected: Set<String>
    let maxSelections: Int
    let excluded: Set<String>

    var skills: [(id: String, name: String, description: String, domain: SkillDomain)] {
        Skill.defaultSkills.filter { $0.domain == domain }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: domain.icon)
                    .foregroundStyle(Constants.Colors.forDomain(domain))
                Text(domain.rawValue)
                    .font(.headline)
            }

            ForEach(skills, id: \.id) { skill in
                let isExcluded = excluded.contains(skill.id)
                let isSelected = selected.contains(skill.id)

                Button {
                    if isSelected {
                        selected.remove(skill.id)
                    } else if selected.count < maxSelections && !isExcluded {
                        selected.insert(skill.id)
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(skill.name)
                                .font(.subheadline.bold())
                            Text(skill.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if isExcluded {
                            Text("Major")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        } else {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(isSelected ? Constants.Colors.primary : .secondary)
                        }
                    }
                    .padding()
                    .background(isSelected ? Constants.Colors.primary.opacity(0.1) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Constants.Colors.primary : Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(isExcluded)
                .opacity(isExcluded ? 0.5 : 1)
            }
        }
    }
}

// MARK: - Confirmation Step

struct ConfirmationStepView: View {
    let name: String
    let majorSkills: Set<String>
    let minorSkills: Set<String>

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Character preview
                VStack(spacing: 12) {
                    Circle()
                        .fill(Constants.Colors.primary.gradient)
                        .frame(width: 100, height: 100)
                        .overlay {
                            Text(name.prefix(1).uppercased())
                                .font(.system(size: 44, weight: .bold))
                                .foregroundStyle(.white)
                        }

                    Text(name)
                        .font(.title.bold())

                    Text("Level 1 Adventurer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // Major skills
                VStack(alignment: .leading, spacing: 8) {
                    Text("Major Skills (Lv. 10)")
                        .font(.headline)

                    ForEach(Array(majorSkills), id: \.self) { skillID in
                        if let skill = Skill.defaultSkills.first(where: { $0.id == skillID }) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text(skill.name)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Minor skills
                VStack(alignment: .leading, spacing: 8) {
                    Text("Minor Skills (Lv. 5)")
                        .font(.headline)

                    ForEach(Array(minorSkills), id: \.self) { skillID in
                        if let skill = Skill.defaultSkills.first(where: { $0.id == skillID }) {
                            HStack {
                                Image(systemName: "star.leadinghalf.filled")
                                    .foregroundStyle(.blue)
                                Text(skill.name)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))

                Text("You can change these later in Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
}

#Preview {
    CharacterCreationView()
}
