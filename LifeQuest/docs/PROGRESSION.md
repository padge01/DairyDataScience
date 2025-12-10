# LifeQuest Progression System

## Overview

The progression system combines Morrowind-style skill-based leveling with modern life gamification. Progress feels organic because it emerges from actual behavior rather than arbitrary goal-setting.

## Core Meters

### Health

Represents physical wellbeing and capacity.

```
Max Health = 100 + (Vitality × 10)
```

**Depletes from:**
- Intense physical activity (-10 to -30)
- Poor sleep (-20 per bad night)
- High stress events (-10 to -20)

**Restores from:**
- Quality sleep (+30 to +50)
- Rest days (+10)
- Healthy meals (+5)

**Effects when low:**
- Below 50%: XP gains reduced by 25%
- Below 25%: "Exhausted" status, 50% XP reduction
- At 0%: "Burnout" - no XP gains, forced rest

### Energy

Represents mental/motivational capacity.

```
Max Energy = 100 + (Willpower × 10)
```

**Depletes from:**
- Deep work sessions (-15 to -30)
- Stressful interactions (-10 to -25)
- Decision fatigue (-5 per major decision)

**Restores from:**
- Sleep (+40 to +60)
- Meditation/breaks (+10)
- Enjoyable activities (+15)

**Effects when low:**
- Below 50%: Mental skill XP reduced 25%
- Below 25%: "Drained" status
- At 0%: "Foggy" - can only do low-effort activities

### Rest Debt

Cumulative sleep deficit (Witcher meditation mechanic).

```
Rest Debt starts at 0, accumulates with poor sleep
```

**Increases from:**
- Less than 7 hours sleep: +1 per hour deficit
- Very poor sleep quality: +2
- All-nighters: +8

**Decreases from:**
- 8+ hours quality sleep: -3 per night
- 9+ hours: -5 per night
- Rest day: -2 bonus

**Effects:**
- Debt > 5: Recovery rate halved
- Debt > 10: Max health/energy reduced
- Debt > 20: "Sleep deprived" - severely limited

## Streak System

### How Streaks Work

Each quest/routine tracks consecutive completion:

```swift
struct Streak {
    let questID: UUID
    var currentDays: Int
    var longestEver: Int
    var lastCompletedDate: Date
}
```

### Streak Multiplier Tiers

| Days | Multiplier | Status |
|------|------------|--------|
| 1-3 | 1.0x | Starting |
| 4-7 | 1.25x | Building |
| 8-14 | 1.5x | Consistent |
| 15-30 | 1.75x | Dedicated |
| 31-60 | 2.0x | Habit Formed |
| 61-90 | 2.25x | Lifestyle |
| 91+ | 2.5x | Mastery |

### Streak Protection

- **Grace Period**: Miss one day without breaking streak (once per week)
- **Vacation Mode**: Pause streaks while traveling
- **Sick Day**: Health-related pause doesn't break streak

### Streak Breaking

When a streak breaks:
- Multiplier resets to 1.0x
- "Streak Lost" notification with stats
- Rebuilding bonus: Faster return to previous tier (25% bonus)

## Character Level System

### Level Calculation

Character level is based on Major skill advancement:

```swift
func calculateCharacterLevel(majorSkills: [Skill]) -> Int {
    let totalMajorLevels = majorSkills.reduce(0) { $0 + $1.level }
    let baseLine = majorSkills.count * 10 // Starting levels
    let gains = totalMajorLevels - baseLine
    return 1 + (gains / 10) // Level up every 10 skill levels gained
}
```

### Level Up Rewards

Each level grants:

1. **Attribute Points** (3 per level)
   - Distributed based on which skills grew most
   - Player can redirect 1 point manually

2. **Perk Points** (1 per 5 levels)
   - Unlock special abilities
   - Example perks:
     - "Early Bird": Bonus XP for morning activities
     - "Night Owl": Reduced energy cost after 8pm
     - "Social Butterfly": 2x Social skill XP
     - "Deep Focus": Extended focus sessions give bonus

3. **Cosmetic Rewards**
   - Character titles
   - UI themes
   - Achievement badges

### Level Milestones

| Level | Title | Unlock |
|-------|-------|--------|
| 5 | Initiate | Custom skill naming |
| 10 | Apprentice | Skill synergy bonuses |
| 15 | Adept | AI insight frequency+  |
| 20 | Journeyman | Advanced analytics |
| 30 | Expert | Coach personality options |
| 40 | Master | Custom quest creation |
| 50 | Grandmaster | Mentor mode (help others) |

## Quest Types

### Daily Quests

Reset each day at configured time (default: 4am).

```swift
struct DailyQuest {
    let id: UUID
    let name: String
    let skills: [SkillGain]
    let baseXP: Int
    var streak: Streak
    var completedToday: Bool
    var autoCompleteSource: HealthKitMetric?
}
```

Examples:
- "Morning Movement" - 10 min activity
- "Deep Work Block" - 90 min focused work
- "Wind Down" - Evening routine completion

### Weekly Quests

Reset each week on configured day (default: Monday).

```swift
struct WeeklyQuest {
    let id: UUID
    let name: String
    let targetCount: Int
    var currentCount: Int
    let skills: [SkillGain]
    let baseXP: Int
}
```

Examples:
- "Train 3x" - Complete 3 workout sessions
- "Social Hour" - 3 meaningful social interactions
- "Learn Something" - Complete learning activity

### One-Time Quests

Special objectives that don't repeat.

```swift
struct OneTimeQuest {
    let id: UUID
    let name: String
    let description: String
    let skills: [SkillGain]
    let xpReward: Int
    var completed: Bool
}
```

Examples:
- "First Steps" - Complete character creation
- "Week One" - Survive first week
- "Century Club" - Reach 100 total skill levels

## Auto-Completion

### HealthKit Mappings

| HealthKit Metric | Quest Match | Skill Gains |
|------------------|-------------|-------------|
| Steps > 10,000 | "Daily Steps" | Endurance +20 |
| Workout (Strength) | "Lift Session" | Strength +30 |
| Workout (Cardio) | "Cardio Session" | Endurance +25 |
| Sleep > 7 hours | "Good Sleep" | Sleep +15, Recovery +10 |
| Sleep > 8 hours | "Great Sleep" | Sleep +25, Recovery +20 |

### Verification

Auto-completed quests show:
- HealthKit icon indicator
- Actual data (e.g., "8,432 steps")
- Option to reject false positives

## Rewards

### XP Economy

```
Total XP = Base XP × Streak Multiplier × Health Modifier × Energy Modifier
```

Example:
- Base: 50 XP
- Streak (Day 15): 1.75x
- Health (80%): 1.0x (no penalty)
- Energy (40%): 0.875x (12.5% penalty)
- **Total: 50 × 1.75 × 1.0 × 0.875 = 76 XP**

### Achievement System

Achievements for milestones:

- "Iron Will" - 30-day streak
- "Renaissance Person" - 5 skills above level 25
- "Specialist" - 1 skill above level 50
- "Balanced" - All maintenance skills above 20
- "Social Butterfly" - All social skills above 25

### Leaderboards (Optional)

- Friends leaderboard
- Anonymous global rankings
- Category-specific (Physical, Mental, etc.)
