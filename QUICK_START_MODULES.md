# Quick Start: Modules System

## For Users

### How to Use
1. **Tap "Train" tab** on home screen (🏋️ icon)
2. **See your progress**: Streak (🔥) and coins (💰) at top
3. **Check daily goal**: Complete one activity from each module
4. **Select an activity**: Tap "Argument Mapping" or other activities
5. **Complete the activity**: Follow on-screen instructions
6. **Get rewarded**: Coins based on your score + streak increase if all modules done

### Streak System
- **Earn 1 streak point** when you complete at least one activity from each of the 3 modules in a single day
- **Streak resets** if you miss a day
- **Coins**: Earned based on performance (50 coins max per activity)

---

## For Developers

### Quick Reference

#### Get User Progress
```dart
final progress = await ProgressService.getProgress();
print('Coins: ${progress.totalCoins}');
print('Streak: ${progress.currentStreak}');
print('Completed today: ${progress.modulesCompletedToday}');
```

#### Record Activity Completion
```dart
final updatedProgress = await ProgressService.completeActivity(
  activityId: 'ct_argument_mapping',
  score: 85.0,  // 0-100
  moduleType: 'criticalThinking',
  metrics: {
    'connectedPremises': 3,
    'totalPremises': 3,
  },
);
// Automatically:
// - Adds coins (50 × 85/100 = 42 coins)
// - Increases streak if all 3 modules done today
// - Saves to SharedPreferences
```

#### Reset Daily Activities
```dart
// Call at app startup
await ProgressService.resetDailyActivities();
```

### File Locations

| What | Where |
|------|-------|
| Models | `lib/models/module.dart` |
| Progress Logic | `lib/services/progress_service.dart` |
| Training Hub | `lib/screens/modules_hub_screen.dart` |
| Argument Mapping | `lib/screens/argument_mapping_screen.dart` |
| Documentation | `MODULES_SYSTEM.md` |

### Adding a New Activity (5 Steps)

**1. Define Activity** in `lib/models/module.dart`:
```dart
Activity(
  id: 'mem_recall',
  type: ActivityType.memoryRecall,
  name: 'Memory Recall',
  description: 'Remember items in sequence',
  difficulty: 'Medium',
  estimatedTime: 4,
  baseReward: 50,
)
```

**2. Create Screen** `lib/screens/memory_recall_screen.dart`:
```dart
class MemoryRecallScreen extends StatefulWidget {
  final Activity activity;
  final Module module;
  final VoidCallback onComplete;
  // ...
}
```

**3. Implement Scoring** (calculate 0-100 score):
```dart
final score = calculateScore(...);  // Your logic here
```

**4. Record Completion**:
```dart
final progress = await ProgressService.completeActivity(
  activityId: widget.activity.id,
  score: score,
  moduleType: _getModuleTypeKey(widget.module.type),
  metrics: {...},
);
```

**5. Register Navigation** in `modules_hub_screen.dart`:
```dart
if (activity.type == ActivityType.memoryRecall) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MemoryRecallScreen(
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

### Scoring Formula

All activities use **0-100 scale**:
- **0-40**: Poor
- **40-60**: Fair
- **60-80**: Good
- **80-100**: Excellent

**Coins Earned** = `50 × (score / 100)`

### Module Types
```dart
enum ModuleType {
  criticalThinking,  // Logic, reasoning
  memory,            // Recall, retention
  creativity,        // Divergent thinking
}
```

### Activity Types
```dart
enum ActivityType {
  argumentMapping,   // Break down arguments
  memoryRecall,      // Remember sequences
  ideaGeneration,    // Generate creative uses
  // Add more as needed
}
```

### Testing

**Reset everything**:
```dart
await ProgressService.clearProgress();
```

**Simulate completion**:
```dart
await ProgressService.completeActivity(
  activityId: 'ct_argument_mapping',
  score: 90.0,
  moduleType: 'criticalThinking',
  metrics: {'test': true},
);
```

### Common Issues

**Q: Streak not increasing?**
A: User must complete one activity from EACH of the 3 modules in the same day.

**Q: Coins not matching score?**
A: Check formula: `coins = 50 × (score / 100)`. Rounded to nearest integer.

**Q: Data not persisting?**
A: Ensure `ProgressService.completeActivity()` is called (not just local state).

**Q: Activity not showing?**
A: Check that activity is added to module's `activities` list and navigation is registered.

### Debug Tips

```dart
// Print current progress
final progress = await ProgressService.getProgress();
print('Progress: ${progress.toJson()}');

// Check what was completed today
print('CT: ${progress.modulesCompletedToday['criticalThinking']}');
print('Mem: ${progress.modulesCompletedToday['memory']}');
print('Cr: ${progress.modulesCompletedToday['creativity']}');

// Check if streak should increase
print('Can increase streak: ${progress.canIncreaseStreak()}');
```

### Performance Tips

- Use `FutureBuilder` to load progress asynchronously
- Call `resetDailyActivities()` once at app startup
- Cache module definitions (they don't change)
- Batch SharedPreferences writes when possible

---

## Architecture Overview

```
User completes activity
        ↓
Activity screen calculates score (0-100)
        ↓
Calls ProgressService.completeActivity()
        ↓
Service calculates coins earned
        ↓
Checks if streak should increase
        ↓
Saves to SharedPreferences
        ↓
Returns updated UserProgress
        ↓
UI updates with new coins/streak
```

---

## Resources

- **Full Documentation**: `MODULES_SYSTEM.md`
- **Implementation Details**: `MODULES_IMPLEMENTATION.md`
- **Code**: `lib/models/module.dart`, `lib/services/progress_service.dart`
