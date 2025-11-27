# Rheto Modules System - Daily Training Architecture

## Overview

The Modules System is the core daily training framework for Rheto. Users complete activities from three cognitive domains (Critical Thinking, Memory, Creativity) to earn in-app currency and build streaks.

## Key Features

### 1. **Three Main Modules**
- **Critical Thinking**: Logic, reasoning, and analytical skills
- **Memory**: Recall accuracy and retention
- **Creativity**: Divergent thinking and originality

### 2. **Daily Streak System**
- Users earn a streak point when they complete **at least one activity from each of the three modules in a single day**
- Streaks are tracked and displayed prominently on the dashboard
- Streak resets if user doesn't complete all three modules on a given day

### 3. **In-App Currency (Coins)**
- Users earn coins based on their performance in activities
- Base reward: 50 coins per activity
- Actual reward = `baseReward × (score / 100)`
- Example: 80/100 score = 40 coins earned

### 4. **Activity System**
Each module contains multiple activities. Currently implemented:
- **Argument Mapping** (Critical Thinking) - Break down arguments into premises and conclusions

## File Structure

```
lib/
├── models/
│   └── module.dart                 # Data models for modules, activities, progress
├── services/
│   ├── progress_service.dart       # Manages user progress, streaks, currency
│   └── scoring_service.dart        # AI scoring via backend
├── screens/
│   ├── modules_hub_screen.dart     # Main training hub with module selection
│   ├── argument_mapping_screen.dart # Argument Mapping activity
│   └── home_screen.dart            # Updated with "Train" tab
```

## Data Models

### Module
```dart
Module(
  type: ModuleType.criticalThinking,
  name: 'Critical Thinking',
  description: 'Enhance logical reasoning and analytical skills',
  icon: 'gears',
  activities: [...],
  dailyTarget: 1,  // Activities needed per day for streak
)
```

### Activity
```dart
Activity(
  id: 'ct_argument_mapping',
  type: ActivityType.argumentMapping,
  name: 'Argument Mapping',
  description: 'Break down arguments into premises and conclusions',
  difficulty: 'Medium',
  estimatedTime: 5,  // minutes
  baseReward: 50,    // coins
)
```

### UserProgress
```dart
UserProgress(
  totalCoins: 245,
  currentStreak: 12,
  lastActivityDate: DateTime.now(),
  completedActivities: [...],
  modulesCompletedToday: {
    'criticalThinking': 1,
    'memory': 0,
    'creativity': 0,
  },
)
```

### ActivityResult
```dart
ActivityResult(
  activityId: 'ct_argument_mapping',
  completedAt: DateTime.now(),
  score: 85.0,  // 0-100
  currencyEarned: 42,
  metrics: {
    'connectedPremises': 3,
    'totalPremises': 3,
    'completenessScore': 40.0,
    'structureScore': 40.0,
    'justificationScore': 5.0,
  },
)
```

## Services

### ProgressService
Manages all user progress, streaks, and currency:

```dart
// Get current progress
final progress = await ProgressService.getProgress();

// Complete an activity
final updatedProgress = await ProgressService.completeActivity(
  activityId: 'ct_argument_mapping',
  score: 85.0,
  moduleType: 'criticalThinking',
  metrics: {...},
);

// Reset daily activities (call at app startup or midnight)
await ProgressService.resetDailyActivities();

// Clear all progress (testing)
await ProgressService.clearProgress();
```

**Streak Logic:**
- Streak increases by 1 when user completes at least one activity from each module in a day
- Streak only increases once per day (checked via `_lastStreakCheckDate`)
- Daily activity counts reset at midnight

### ScoringService
Handles AI-based scoring for activities:

```dart
// Score justification text
final scores = await ScoringService.scoreJustification(
  question: 'Explain the logical structure',
  userAnswer: userInput,
);
// Returns: {clarity, depth, logical_structure, total (0-100)}
```

## Screens

### ModulesHubScreen
The main training dashboard showing:
- Current streak and total coins (header)
- Daily goal progress (one activity per module)
- All available modules with their activities
- Activity cards with difficulty, time, and reward info

**Navigation:**
- Accessible via "Train" tab in home screen bottom nav
- Tapping an activity navigates to that activity's screen

### ArgumentMappingScreen
The first implemented activity (Critical Thinking module):

**Task:**
1. User sees a claim/conclusion
2. User identifies and connects premises to the conclusion
3. User explains the logical structure in text form
4. System evaluates and scores the response

**Scoring:**
- Completeness (0-40): How many premises identified
- Logical Structure (0-40): Correctness of connections
- Justification Quality (0-20): AI evaluation of explanation
- **Total: 0-100**

**Reward Calculation:**
- Base reward: 50 coins
- Actual reward: `50 × (score / 100)`
- Example: 80/100 = 40 coins

## Adding New Activities

### Step 1: Define the Activity
In `lib/models/module.dart`, add to the appropriate module:

```dart
Activity(
  id: 'ct_new_activity',
  type: ActivityType.newActivityType,  // Add to enum if needed
  name: 'New Activity Name',
  description: 'What it does',
  difficulty: 'Medium',
  estimatedTime: 5,
  baseReward: 50,
)
```

### Step 2: Create the Activity Screen
Create `lib/screens/new_activity_screen.dart` extending `StatefulWidget`:

```dart
class NewActivityScreen extends StatefulWidget {
  final Activity activity;
  final Module module;
  final VoidCallback onComplete;

  const NewActivityScreen({
    required this.activity,
    required this.module,
    required this.onComplete,
  });

  @override
  State<NewActivityScreen> createState() => _NewActivityScreenState();
}
```

### Step 3: Implement Scoring Logic
Calculate a 0-100 score based on activity-specific metrics:

```dart
final score = calculateScore(...);

// Record completion
final progress = await ProgressService.completeActivity(
  activityId: widget.activity.id,
  score: score,
  moduleType: _getModuleTypeKey(widget.module.type),
  metrics: {
    'metric1': value1,
    'metric2': value2,
  },
);
```

### Step 4: Register Navigation
In `modules_hub_screen.dart`, add to `_navigateToActivity()`:

```dart
if (activity.type == ActivityType.newActivityType) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => NewActivityScreen(
        activity: activity,
        module: module,
        onComplete: () {
          setState(() {
            _progressFuture = _loadProgress();
          });
        },
      ),
    ),
  );
}
```

## Neuroscience Targets

Each activity targets specific neural networks:

### Argument Mapping
- **Target**: Frontoparietal network
- **Effect**: Enhances structured reasoning, suppresses snap intuitive judgments
- **Metrics**: Premise identification, logical structure, explanation quality

### Future Activities
- **Memory Recall**: Hippocampus and temporal lobe
- **Idea Generation**: Default Mode Network (DMN)

## Testing

### Reset User Progress
```dart
// In debug console or test
await ProgressService.clearProgress();
```

### Simulate Activity Completion
```dart
final progress = await ProgressService.completeActivity(
  activityId: 'ct_argument_mapping',
  score: 85.0,
  moduleType: 'criticalThinking',
  metrics: {'test': true},
);
print('Streak: ${progress.currentStreak}');
print('Coins: ${progress.totalCoins}');
```

## Future Enhancements

1. **AI-Generated Arguments**: Dynamically generate argument claims via backend
2. **Difficulty Scaling**: Adjust difficulty based on user performance
3. **Leaderboards**: Compare streaks and coins with other users
4. **Achievements**: Badges for milestones (7-day streak, 1000 coins, etc.)
5. **Spaced Repetition**: Suggest activities based on weak domains
6. **Analytics Dashboard**: Detailed performance tracking per domain
7. **Adaptive Difficulty**: ML-based difficulty adjustment
8. **Social Features**: Share streaks, compete with friends

## Persistence

All user progress is stored in `SharedPreferences`:
- `user_progress`: Full UserProgress JSON
- `last_streak_check_date`: Last date streak was incremented

Data is automatically loaded on app startup and persists across sessions.
