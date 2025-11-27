# Contradiction Hunter Activity Implementation

## Overview
Successfully implemented **Contradiction Hunter**, the first activity in the Critical Thinking module. This dynamic reasoning game forces users to detect logical conflicts hidden inside short narratives.

## Architecture

### Backend (Node.js - `backend/server.js`)

#### Endpoint 1: `/generate-contradiction-story` (POST)
Generates unique micro-stories with embedded contradictions.

**Request:**
```json
{
  "difficulty": "medium",
  "previousStories": []
}
```

**Response:**
```json
{
  "story": "...",
  "contradictions": [
    {
      "type": "temporal",
      "description": "..."
    }
  ],
  "difficulty": "medium",
  "expectedContradictionCount": 3
}
```

**Features:**
- Generates 60-90 second read-time stories (150-250 words)
- Difficulty levels: easy (2 contradictions), medium (2-3), hard (3-4)
- Varies contradiction types to prevent repetition:
  - Temporal (event order impossible)
  - Causal (effect doesn't follow cause)
  - Motivation inconsistency
  - Hidden assumption shifts
  - Logical impossibilities
- Tracks previous stories to ensure uniqueness

#### Endpoint 2: `/score-contradictions` (POST)
Evaluates user's contradiction detection and justification.

**Request:**
```json
{
  "story": "...",
  "detectedContradictions": ["...", "..."],
  "justification": "...",
  "expectedContradictions": ["temporal: ...", "causal: ..."]
}
```

**Response:**
```json
{
  "accuracy_rate": 8,
  "bias_detection_rate": 6,
  "cognitive_reflection": 7,
  "justification_quality": 8,
  "total": 75
}
```

**Scoring Formula:**
```
Total Score = ((accuracy_rate/10 × 3) + (bias_detection_rate/10 × 2) + 
               (cognitive_reflection/10 × 1) + (justification_quality/10 × 4)) × 10
```

### Frontend (Flutter)

#### Screen: `lib/screens/contradiction_hunter_screen.dart`

**User Flow:**
1. Load story from backend
2. Display story with 90-second countdown timer
3. After timer expires, show contradiction selection interface
4. User enters detected contradictions in text field
5. User writes detailed justification
6. Submit for AI evaluation
7. Display detailed scoring breakdown

**Key Components:**
- `_loadStoryFromAPI()` - Fetches unique story from backend
- `_startStoryTimer()` - 90-second countdown timer
- `_submitActivity()` - Validates input and sends to backend for scoring
- `_showCompletionDialog()` - Displays results with metrics breakdown

**Metrics Displayed:**
- Accuracy Rate (0-10): Did user correctly identify real contradictions?
- Bias Detection Rate (0-10): Did they catch assumption shifts?
- Cognitive Reflection (0-10): How deeply did they think?
- Justification Quality (0-10): Is explanation clear and logical?

#### Integration Points

**1. Module Definition** (`lib/models/module.dart`)
```dart
Activity(
  id: 'ct_contradiction_hunter',
  type: ActivityType.contradictionHunter,
  name: 'Contradiction Hunter',
  description: 'Detect logical conflicts hidden in micro-stories',
  difficulty: 'Medium',
  estimatedTime: 6,
  baseReward: 60,
)
```

**2. Activity Navigation** (`lib/screens/activities_screen.dart`)
- Added `_navigateToActivity()` method
- Routes to `ContradictionHunterScreen` when activity is selected
- Updated help text methods with Contradiction Hunter content

**3. Progress Tracking** (`lib/services/progress_service.dart`)
- Records activity completion with metrics
- Calculates coin rewards based on score
- Updates streak tracking

## Cognitive Science Basis

### Brain Regions Activated
- **Anterior Cingulate Cortex (ACC)**: Error-monitoring system detects inconsistencies
- **Frontoparietal Control Network (FPN)**: Maintains rule-based reasoning across narrative
- **Lateral Prefrontal Cortex**: Resolves cognitive conflict and re-evaluates assumptions

### Learning Outcomes
- Detects logical inconsistencies
- Evaluates conflicting claims
- Overrides intuitive but incorrect reasoning
- Improves analytical thinking and critical reasoning

## Difficulty Progression

### Easy
- 2 surface-level contradictions
- Obvious temporal or causal conflicts
- Shorter stories

### Medium (Default)
- 2-3 multi-layered contradictions
- Mix of temporal, causal, and assumption-based conflicts
- Moderate story length

### Hard
- 3-4 philosophical paradox-style contradictions
- Complex assumption shifts
- Longer, more intricate narratives

## Reward System

**Base Reward:** 60 coins

**Calculation:**
```
Coins Earned = 60 × (Total Score / 100)
```

**Streak Bonus:**
- Completing activity contributes to daily streak
- Streak increases when user completes activities from all 3 modules in one day

## Testing Checklist

- [ ] Backend generates unique stories on each call
- [ ] Contradiction types vary across iterations
- [ ] 90-second timer works correctly
- [ ] Story displays properly with readable formatting
- [ ] User can input contradictions and justification
- [ ] Scoring API returns valid scores (0-10 range)
- [ ] Final score calculation is correct (0-100)
- [ ] Completion dialog displays all metrics
- [ ] Coins are awarded based on score
- [ ] Activity progress is saved to storage
- [ ] Navigation back to activities list works

## Future Enhancements

1. **Difficulty Selection**: Allow users to choose difficulty before starting
2. **Hint System**: Provide hints after certain time thresholds
3. **Leaderboard**: Track best scores across users
4. **Story Categories**: Different story themes (business, science, history, etc.)
5. **Explanation Feedback**: Show AI's reasoning for why contradictions were missed
6. **Adaptive Difficulty**: Adjust difficulty based on user performance
7. **Batch Stories**: Generate multiple stories for practice sessions
8. **Analytics**: Track which contradiction types users struggle with most

## Dependencies

**Backend:**
- Express.js
- Hugging Face Inference API
- dotenv

**Frontend:**
- Flutter
- http package
- font_awesome_flutter
- shared_preferences (for progress storage)

## Setup Instructions

1. Ensure backend is running: `npm start` (port 3000)
2. Ensure HF_TOKEN is set in `backend/.env`
3. Run Flutter app: `flutter run`
4. Navigate to Critical Thinking module
5. Select "Contradiction Hunter" activity
6. Complete the activity

## Notes

- All stories are generated dynamically to ensure uniqueness
- Contradiction types are randomized to prevent pattern recognition
- AI scoring is strict and demanding (most users score below 6 on individual metrics)
- Timer is visual and encourages quick reading comprehension
- Justification field requires thoughtful analysis
