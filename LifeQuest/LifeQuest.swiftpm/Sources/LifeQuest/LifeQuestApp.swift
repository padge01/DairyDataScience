import SwiftUI
import SwiftData

/// Main app entry point
@main
struct LifeQuestApp: App {
    // MARK: - SwiftData Container

    let modelContainer: ModelContainer

    // MARK: - Services

    @State private var characterViewModel: CharacterViewModel
    @State private var healthKitService: HealthKitService
    @State private var aiService: AIService

    // MARK: - Initialization

    init() {
        // Configure SwiftData
        let schema = Schema([
            Character.self,
            Skill.self,
            Quest.self,
            Activity.self,
            Memory.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none  // Enable for iCloud sync: .automatic
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Initialize services
        let context = modelContainer.mainContext
        let healthKit = HealthKitService()
        let ai = AIService()
        let progression = ProgressionEngine(modelContext: context)
        let memory = MemoryManager(modelContext: context, aiService: ai)
        let quest = QuestEngine(
            modelContext: context,
            healthKitService: healthKit,
            progressionEngine: progression
        )

        // Initialize view model
        let viewModel = CharacterViewModel(
            modelContext: context,
            progressionEngine: progression,
            questEngine: quest,
            healthKitService: healthKit,
            aiService: ai,
            memoryManager: memory
        )

        _characterViewModel = State(initialValue: viewModel)
        _healthKitService = State(initialValue: healthKit)
        _aiService = State(initialValue: ai)
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(characterViewModel)
                .environment(healthKitService)
                .environment(aiService)
                .task {
                    // Load character on launch
                    characterViewModel.loadCharacter()

                    // Request HealthKit authorization
                    _ = await healthKitService.requestAuthorization()

                    // Sync health data
                    await characterViewModel.syncHealthData()
                }
        }
        .modelContainer(modelContainer)
    }
}

// MARK: - Content View (Root Navigation)

struct ContentView: View {
    @Environment(CharacterViewModel.self) private var viewModel

    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.character == nil {
                CharacterCreationView()
            } else {
                MainTabView()
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading your quest...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
