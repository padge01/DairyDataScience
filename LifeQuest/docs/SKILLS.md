# LifeQuest Skill System

## Overview

The skill system is inspired by The Elder Scrolls III: Morrowind. Players have access to all skills, but designate Major and Minor skills during character creation that contribute to level progression.

## Skill Domains

### Physical (Body)

Skills related to physical fitness and bodily capabilities.

| Skill | Description | Auto-Track Sources |
|-------|-------------|-------------------|
| **Strength** | Raw power, lifting, resistance training | Weight workouts |
| **Endurance** | Cardiovascular fitness, stamina | Steps, running, cycling |
| **Mobility** | Flexibility, range of motion, agility | Yoga, stretching workouts |
| **Recovery** | Ability to heal and restore | Sleep quality, rest days |

### Mental (Mind)

Skills related to cognitive function and mental capabilities.

| Skill | Description | Auto-Track Sources |
|-------|-------------|-------------------|
| **Focus** | Concentration, deep work ability | Focus modes, screen time |
| **Learning** | Acquiring new knowledge | Reading, courses |
| **Problem-Solving** | Analytical thinking, debugging | Coding sessions, puzzles |
| **Creativity** | Novel ideation, artistic expression | Creative activities |

### Social (Connection)

Skills related to interpersonal interaction.

| Skill | Description | Auto-Track Sources |
|-------|-------------|-------------------|
| **Communication** | Clear expression, writing, speaking | Meetings, writing |
| **Leadership** | Guiding others, decision-making | Team activities |
| **Empathy** | Understanding others' perspectives | Relationship time |
| **Networking** | Building professional connections | Events, outreach |

### Professional (Craft)

Domain-specific expertise. Users can define custom skills here.

| Skill | Description | Auto-Track Sources |
|-------|-------------|-------------------|
| **[User-Defined]** | Primary professional domain | Manual logging |
| **[User-Defined]** | Secondary expertise | Manual logging |
| **[User-Defined]** | Emerging skill area | Manual logging |

Default examples:
- Programming
- Design
- Writing
- Sales
- Management

### Maintenance (Sustain)

Life management and self-care skills.

| Skill | Description | Auto-Track Sources |
|-------|-------------|-------------------|
| **Sleep** | Rest quality and consistency | Sleep analysis |
| **Nutrition** | Healthy eating habits | Manual logging |
| **Stress Management** | Handling pressure, relaxation | HRV, meditation |
| **Finance** | Money management | Manual logging |

## Skill Configuration

### Major Skills (5 max)

- Contribute fully to character level progression
- Start at level 10
- Represent your core focus areas

### Minor Skills (5 max)

- Contribute 50% to character level progression
- Start at level 5
- Secondary areas of development

### Misc Skills (remainder)

- Tracked but don't contribute to leveling
- Start at level 1
- Can be promoted to Minor/Major later

## XP and Leveling

### XP Awards

Base XP values for activities:

| Activity Type | Base XP | Example |
|--------------|---------|---------|
| Micro | 5-10 | Took stairs, drank water |
| Small | 15-25 | 15 min walk, short reading |
| Medium | 30-50 | Workout, focused work hour |
| Large | 60-100 | Long training session, deep work block |
| Major | 150+ | Competition, major project milestone |

### Streak Multipliers

Consecutive days of skill use multiply XP:

```
Days 1-3:    1.0x  (baseline)
Days 4-7:    1.25x (building)
Days 8-14:   1.5x  (consistent)
Days 15-30:  1.75x (dedicated)
Days 31+:    2.0x  (mastery)
```

### Level Requirements

XP required for each level follows a curve:

```swift
func xpForLevel(_ level: Int) -> Int {
    // Morrowind-inspired curve
    return Int(pow(Double(level), 1.5) * 100)
}
```

| Level | Total XP Required | XP to Next |
|-------|------------------|------------|
| 1 | 0 | 100 |
| 5 | 1,118 | 316 |
| 10 | 3,162 | 486 |
| 25 | 12,500 | 980 |
| 50 | 35,355 | 1,485 |
| 75 | 64,952 | 1,915 |
| 100 | 100,000 | — |

## Character Leveling

Character level increases when the sum of Major skill level gains reaches a threshold.

### Level Up Requirements

```
Major skill levels gained since last level-up >= 10
```

Example:
- Start: Strength 10, Endurance 10, Focus 10, Learning 10, Sleep 10
- Train: Strength → 12, Focus → 15, Sleep → 13
- Gains: 2 + 5 + 3 = 10 → Level up!

### Attribute Bonuses

On level up, gain attribute points based on which skills improved:

| Attribute | Governed By | Effect |
|-----------|-------------|--------|
| **Vitality** | Physical skills | Max health |
| **Willpower** | Mental skills | Max energy |
| **Charisma** | Social skills | Coach insight quality |
| **Expertise** | Professional skills | XP bonus in domain |
| **Balance** | Maintenance skills | Recovery rate |

## Skill Synergies

Some activities naturally train multiple skills:

| Activity | Primary | Secondary |
|----------|---------|-----------|
| BJJ training | Endurance +3 | Mobility +1, Focus +1 |
| Deep work session | Focus +2 | Problem-Solving +1 |
| Team presentation | Communication +2 | Leadership +1 |
| Meditation | Stress Management +2 | Focus +1 |

The AI interprets activities and determines appropriate skill gains based on context.

## Skill Decay (Optional)

Skills can slowly decay if not used:

- No activity in 7 days: Warning notification
- No activity in 14 days: -1% XP per day
- Never below previous level threshold

This encourages balanced development but can be disabled in settings.
