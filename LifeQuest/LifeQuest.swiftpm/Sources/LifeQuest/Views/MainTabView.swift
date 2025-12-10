import SwiftUI

/// Main tab navigation for the app
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            CharacterSheetView()
                .tabItem {
                    Label("Character", systemImage: "person.fill")
                }
                .tag(0)

            QuestLogView()
                .tabItem {
                    Label("Quests", systemImage: "list.bullet.clipboard")
                }
                .tag(1)

            ActivityLogView()
                .tabItem {
                    Label("Log", systemImage: "plus.circle.fill")
                }
                .tag(2)

            CoachView()
                .tabItem {
                    Label("Coach", systemImage: "sparkles")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .tint(Constants.Colors.primary)
    }
}

#Preview {
    MainTabView()
}
