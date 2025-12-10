# LifeQuest Architecture

## Overview

LifeQuest follows a clean MVVM architecture with service layers for business logic.

```
┌─────────────────────────────────────────────────────────────┐
│                      PRESENTATION                           │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                   SwiftUI Views                         ││
│  │  CharacterSheet │ Skills │ Quests │ Coach │ Settings   ││
│  └─────────────────────────────────────────────────────────┘│
│                            │                                │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                   ViewModels                            ││
│  │  @Observable classes that bridge Views and Services     ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                      DOMAIN LAYER                           │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                     Services                            ││
│  │  ProgressionEngine │ QuestEngine │ AIService │ Memory   ││
│  └─────────────────────────────────────────────────────────┘│
│                            │                                │
│  ┌─────────────────────────────────────────────────────────┐│
│  │                     Models                              ││
│  │  Character │ Skill │ Quest │ Activity │ Memory          ││
│  └─────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────────┐
│                      DATA LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  SwiftData   │  │  HealthKit   │  │  Claude API  │      │
│  │  (Local DB)  │  │  (Health)    │  │  (AI)        │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

### Activity Logging Flow

```
User Input (natural language)
       │
       ▼
┌─────────────────┐
│   AIService     │ ──── Claude API call with context
└─────────────────┘
       │
       ▼
┌─────────────────┐
│ Interpretation  │ ──── { skills: [{id, xp}], notes: string }
└─────────────────┘
       │
       ▼
┌─────────────────┐
│ProgressionEngine│ ──── Apply XP, calculate levels, streaks
└─────────────────┘
       │
       ▼
┌─────────────────┐
│   SwiftData     │ ──── Persist changes
└─────────────────┘
       │
       ▼
┌─────────────────┐
│   UI Update     │ ──── Character sheet refreshes
└─────────────────┘
```

### HealthKit Sync Flow

```
┌─────────────────┐
│HealthKitService│ ──── Background observer queries
└─────────────────┘
       │
       ▼
┌─────────────────┐
│  New samples    │ ──── Steps, workouts, sleep
└─────────────────┘
       │
       ▼
┌─────────────────┐
│  Auto-complete  │ ──── Match to quests, generate activities
└─────────────────┘
       │
       ▼
┌─────────────────┐
│ProgressionEngine│ ──── Award XP, update recovery
└─────────────────┘
```

## Key Services

### ProgressionEngine

Handles all XP and leveling calculations:

- `awardXP(skill:amount:streak:)` - Apply XP with multipliers
- `calculateLevel(totalXP:)` - Determine level from XP
- `xpForLevel(_:)` - XP required for a given level
- `streakMultiplier(days:)` - Calculate streak bonus
- `processRecovery(sleep:)` - Update health/energy from rest

### QuestEngine

Manages routines and tasks:

- `generateDailyQuests()` - Create today's quest list
- `completeQuest(_:)` - Mark complete, award XP
- `checkAutoComplete()` - Match HealthKit data to quests
- `updateStreaks()` - Increment/reset streak counters

### AIService

Interfaces with Claude API:

- `interpretActivity(_:context:)` - Parse natural language
- `generateInsights(character:history:)` - Weekly analysis
- `suggestQuests(character:patterns:)` - Recommend new habits
- `chat(message:memory:)` - Conversational coaching

### MemoryManager

Maintains AI context:

- `addEpisode(_:)` - Store activity with context
- `extractPatterns()` - Identify recurring behaviors
- `buildContext(limit:)` - Assemble prompt context
- `consolidate()` - Merge old episodes into patterns

### HealthKitService

Syncs health data:

- `requestAuthorization()` - Get permissions
- `observeSteps()` - Background step tracking
- `fetchWorkouts(since:)` - Get recent workouts
- `fetchSleep(since:)` - Get sleep data
- `calculateRecovery()` - Determine rest quality

## State Management

Using Swift's `@Observable` macro for reactive state:

```swift
@Observable
class CharacterViewModel {
    var character: Character
    var skills: [Skill]
    var todaysQuests: [Quest]

    private let progressionEngine: ProgressionEngine
    private let questEngine: QuestEngine
}
```

Views observe these view models and automatically update when properties change.

## Persistence

### SwiftData Models

All models use `@Model` macro for automatic persistence:

```swift
@Model
class Character {
    var name: String
    var level: Int
    var totalXP: Int
    // ...
}
```

### iCloud Sync

SwiftData automatically syncs to iCloud when configured:

```swift
let container = try ModelContainer(
    for: Character.self, Skill.self, Quest.self,
    configurations: ModelConfiguration(cloudKitDatabase: .automatic)
)
```

## Security Considerations

1. **API Key Storage** - Claude API key stored in Keychain
2. **Health Data** - Never sent to external APIs
3. **Memory Context** - Anonymized before AI calls
4. **Local-First** - App fully functional offline
