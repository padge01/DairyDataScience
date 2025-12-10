import SwiftUI

/// Settings and configuration view
struct SettingsView: View {
    @Environment(CharacterViewModel.self) private var viewModel
    @State private var apiKey = ""
    @State private var showingAPIKey = false
    @State private var healthKitEnabled = false
    @State private var notificationsEnabled = true
    @State private var dailyResetTime = Date()

    var body: some View {
        NavigationStack {
            Form {
                // Character Section
                if let character = viewModel.character {
                    Section("Character") {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(character.name)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Level")
                            Spacer()
                            Text("\(character.level)")
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Text("Created")
                            Spacer()
                            Text(character.createdAt.shortDate)
                                .foregroundStyle(.secondary)
                        }

                        NavigationLink("Edit Skills") {
                            EditSkillsView(character: character)
                        }
                    }
                }

                // AI Configuration
                Section {
                    HStack {
                        if showingAPIKey {
                            TextField("API Key", text: $apiKey)
                                .textContentType(.password)
                        } else {
                            SecureField("API Key", text: $apiKey)
                        }

                        Button {
                            showingAPIKey.toggle()
                        } label: {
                            Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                        }
                    }

                    Button("Save API Key") {
                        // Save to keychain
                    }
                    .disabled(apiKey.isEmpty)
                } header: {
                    Text("Claude AI")
                } footer: {
                    Text("Get your API key from console.anthropic.com")
                }

                // HealthKit
                Section {
                    Toggle("Enable HealthKit", isOn: $healthKitEnabled)

                    if healthKitEnabled {
                        NavigationLink("HealthKit Permissions") {
                            HealthKitSettingsView()
                        }
                    }
                } header: {
                    Text("Health Integration")
                } footer: {
                    Text("Auto-track steps, workouts, and sleep for skill gains")
                }

                // Notifications
                Section("Notifications") {
                    Toggle("Daily Reminders", isOn: $notificationsEnabled)

                    if notificationsEnabled {
                        DatePicker("Reminder Time", selection: $dailyResetTime, displayedComponents: .hourAndMinute)
                    }
                }

                // Quest Settings
                Section {
                    DatePicker(
                        "Daily Reset Time",
                        selection: $dailyResetTime,
                        displayedComponents: .hourAndMinute
                    )

                    Picker("Weekly Reset Day", selection: .constant(1)) {
                        Text("Monday").tag(1)
                        Text("Sunday").tag(0)
                    }
                } header: {
                    Text("Quest Timing")
                } footer: {
                    Text("Daily quests reset at the specified time")
                }

                // Data
                Section("Data") {
                    NavigationLink("Export Data") {
                        ExportDataView()
                    }

                    NavigationLink("Import Data") {
                        ImportDataView()
                    }

                    Button("Clear All Data", role: .destructive) {
                        // Show confirmation
                    }
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Constants.appVersion)
                            .foregroundStyle(.secondary)
                    }

                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)

                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)

                    NavigationLink("Acknowledgments") {
                        AcknowledgmentsView()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

// MARK: - Edit Skills View

struct EditSkillsView: View {
    let character: Character
    @State private var majorSkills: Set<String> = []
    @State private var minorSkills: Set<String> = []

    var body: some View {
        List {
            Section {
                Text("Select 5 Major skills that contribute fully to leveling, and 5 Minor skills that contribute partially.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(SkillDomain.allCases, id: \.self) { domain in
                Section(domain.rawValue) {
                    ForEach(skillsForDomain(domain), id: \.id) { skill in
                        SkillSelectionRow(
                            skill: skill,
                            isMajor: majorSkills.contains(skill.skillID),
                            isMinor: minorSkills.contains(skill.skillID),
                            onToggleMajor: { toggleMajor(skill.skillID) },
                            onToggleMinor: { toggleMinor(skill.skillID) }
                        )
                    }
                }
            }
        }
        .navigationTitle("Edit Skills")
        .onAppear {
            majorSkills = Set(character.majorSkillIDs)
            minorSkills = Set(character.minorSkillIDs)
        }
    }

    func skillsForDomain(_ domain: SkillDomain) -> [Skill] {
        character.skills.filter { $0.domain == domain }
    }

    func toggleMajor(_ skillID: String) {
        if majorSkills.contains(skillID) {
            majorSkills.remove(skillID)
        } else if majorSkills.count < 5 {
            majorSkills.insert(skillID)
            minorSkills.remove(skillID)
        }
    }

    func toggleMinor(_ skillID: String) {
        if minorSkills.contains(skillID) {
            minorSkills.remove(skillID)
        } else if minorSkills.count < 5 {
            minorSkills.insert(skillID)
            majorSkills.remove(skillID)
        }
    }
}

struct SkillSelectionRow: View {
    let skill: Skill
    let isMajor: Bool
    let isMinor: Bool
    let onToggleMajor: () -> Void
    let onToggleMinor: () -> Void

    var body: some View {
        HStack {
            Text(skill.name)

            Spacer()

            Button {
                onToggleMajor()
            } label: {
                Text("Major")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isMajor ? .yellow : .secondary.opacity(0.2))
                    .foregroundStyle(isMajor ? .black : .secondary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
                onToggleMinor()
            } label: {
                Text("Minor")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isMinor ? .blue : .secondary.opacity(0.2))
                    .foregroundStyle(isMinor ? .white : .secondary)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Placeholder Views

struct HealthKitSettingsView: View {
    var body: some View {
        List {
            Section("Read Permissions") {
                Toggle("Steps", isOn: .constant(true))
                Toggle("Workouts", isOn: .constant(true))
                Toggle("Sleep Analysis", isOn: .constant(true))
                Toggle("Heart Rate", isOn: .constant(false))
            }

            Button("Request Permissions") {
                // Request HealthKit permissions
            }
        }
        .navigationTitle("HealthKit")
    }
}

struct ExportDataView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Export Your Data")
                .font(.title2.bold())

            Text("Download all your character data, activities, and progress as a JSON file.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Export to Files") {
                // Export logic
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Export")
    }
}

struct ImportDataView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Import Data")
                .font(.title2.bold())

            Text("Restore from a previously exported JSON file.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Select File") {
                // Import logic
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Import")
    }
}

struct AcknowledgmentsView: View {
    var body: some View {
        List {
            Section("Inspiration") {
                Text("The Elder Scrolls III: Morrowind")
                Text("The Witcher 3: Wild Hunt")
            }

            Section("Technologies") {
                Text("SwiftUI")
                Text("SwiftData")
                Text("HealthKit")
                Text("Claude API by Anthropic")
            }
        }
        .navigationTitle("Acknowledgments")
    }
}

#Preview {
    SettingsView()
}
