# LifeQuest

An AI-powered life coach with RPG progression mechanics inspired by Morrowind's skill system.

## Concept

LifeQuest is **descriptive rather than prescriptive** - it observes what you do and reflects progress, rather than nagging about what you said you'd do. Your "character build" reveals itself through behavior patterns, not upfront commitments.

### Core Philosophy

- **Emergent Goals** - Your build reveals itself through behavior, not planning
- **Compound Progression** - Leveling happens naturally, creating satisfying "ding" moments
- **Rest & Recovery** - Like The Witcher, you need sleep to heal and restore energy
- **AI Memory** - The coach learns your patterns and provides contextual insights

## Features

### Character System
- **27+ Skills** across 5 domains (Physical, Mental, Social, Professional, Maintenance)
- **Major/Minor Skills** - Pick 5-7 focus areas that drive level-ups
- **Health/Energy/Rest** meters with recovery mechanics
- **Level Progression** with rewards and unlocks

### Quest System
- **Daily Routines** - Recurring tasks that build habits
- **Weekly Goals** - Larger objectives with flexible timing
- **Streak Multipliers** - Consistency compounds XP gains (up to 2x)
- **Auto-completion** via HealthKit integration

### HealthKit Integration
- **Steps** → Endurance XP
- **Workouts** → Strength/Mobility XP (based on workout type)
- **Sleep** → Recovery + Sleep skill XP
- **Heart Rate Variability** → Stress management insights

### AI Coach
- **Activity Interpretation** - Natural language → skill gains
- **Pattern Recognition** - "You train best on Tuesdays after..."
- **Contextual Suggestions** - Based on your actual behavior
- **Memory Layer** - Accumulates understanding of your life

## Project Structure

```
LifeQuest/
├── LifeQuest.swiftpm/
│   ├── Package.swift              # Swift Package definition
│   └── Sources/LifeQuest/
│       ├── LifeQuestApp.swift     # App entry point
│       ├── Models/                # Data models
│       │   ├── Character.swift
│       │   ├── Skill.swift
│       │   ├── Quest.swift
│       │   ├── Activity.swift
│       │   └── Memory.swift
│       ├── Views/                 # SwiftUI views
│       │   ├── MainTabView.swift
│       │   ├── CharacterSheet/
│       │   ├── Skills/
│       │   ├── Quests/
│       │   ├── Coach/
│       │   └── Settings/
│       ├── ViewModels/            # ObservableObject view models
│       │   ├── CharacterViewModel.swift
│       │   ├── QuestViewModel.swift
│       │   └── CoachViewModel.swift
│       ├── Services/              # Business logic
│       │   ├── ProgressionEngine.swift
│       │   ├── HealthKitService.swift
│       │   ├── QuestEngine.swift
│       │   ├── AIService.swift
│       │   └── MemoryManager.swift
│       └── Utils/                 # Helpers
│           ├── Constants.swift
│           └── Extensions.swift
├── docs/
│   ├── ARCHITECTURE.md
│   ├── SKILLS.md
│   ├── PROGRESSION.md
│   └── AI_PROMPTS.md
└── README.md
```

## Skill Domains

| Domain | Skills | Auto-Track |
|--------|--------|------------|
| **Physical** | Strength, Endurance, Mobility, Recovery | Workouts, Steps, Sleep |
| **Mental** | Focus, Learning, Problem-solving, Creativity | Screen time, Reading |
| **Social** | Communication, Leadership, Empathy, Networking | Calendar events |
| **Professional** | Domain expertise (user-defined) | Manual logging |
| **Maintenance** | Sleep, Nutrition, Stress, Finance | HealthKit, Manual |

## Progression Curves

Skills use exponential XP requirements:

| Level Range | Character | Gains Feel Like |
|-------------|-----------|-----------------|
| 1-10 | Novice | Quick wins, establishing baseline |
| 10-25 | Apprentice | Building consistency |
| 25-50 | Journeyman | Deep practice, noticeable competence |
| 50-75 | Expert | Mastery phase, slower but meaningful |
| 75-100 | Master | Elite territory, genuine expertise |

## Tech Stack

- **SwiftUI** - Native iOS UI framework
- **SwiftData** - Persistence with iCloud sync
- **HealthKit** - Fitness and health data
- **Claude API** - AI interpretation and coaching
- **Combine** - Reactive data flow

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Apple Developer account (for HealthKit)

## Getting Started

1. Open `LifeQuest.swiftpm` in Xcode
2. Configure signing & capabilities
3. Add HealthKit capability
4. Add your Claude API key to Settings
5. Build and run

## Privacy

- All personal data stays on-device
- Only anonymized context sent to Claude API
- HealthKit data never leaves the device
- Optional iCloud sync (encrypted)
