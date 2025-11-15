# AI Scoring System Setup Guide

This document explains how to set up and run the AI scoring system for Rheto.

## Architecture Overview

The system consists of:

1. **Flutter Frontend** (`lib/screens/` and `lib/services/`)
   - Assessment screens for collecting user responses
   - Results display screen
   - Scoring service for API communication

2. **Node.js Backend** (`backend/`)
   - Express server running on port 3000
   - Hugging Face Inference API integration
   - Three scoring endpoints for different assessment types

## Prerequisites

- Node.js 16+ installed
- Hugging Face API token (get one from https://huggingface.co/settings/tokens)
- Flutter SDK installed

## Backend Setup

### 1. Install Backend Dependencies

```bash
cd backend
npm install
```

### 2. Configure Environment Variables

Create a `.env` file in the `backend/` directory:

```
PORT=3000
```

Replace the token with your actual Hugging Face token.

### 3. Start the Backend Server

```bash
npm start
```

You should see:
```
Rheto Scoring API running on port 3000
```

## Flutter Setup

### 1. Install Dependencies

```bash
flutter pub get
```

This will install the `http` package needed for API communication.

### 2. Update API Base URL (if needed)

If your backend is running on a different machine or port, update the base URL in:
- `lib/services/scoring_service.dart` (line 3)

For local testing:
```dart
static const String baseUrl = 'http://localhost:3000';
```

For testing on physical devices, use your machine's IP address:
```dart
static const String baseUrl = 'http://192.168.x.x:3000';
```

## Running the Assessment

### 1. Start the Backend

```bash
cd backend
npm start
```

### 2. Run the Flutter App

```bash
flutter run
```

### 3. Navigate to Assessment

1. From the home screen, click "Initial Assessment"
2. Complete all three assessments:
   - **Critical Thinking** (Logic, Bias Detection, Cognitive Reflection, Justification)
   - **Memory Efficiency** (Immediate Recall, Distractor Task, Delayed Recall)
   - **Creativity** (Divergent Uses, Twist Round, Refinement)
3. After completing all assessments, the system will:
   - Show a "Analyzing your responses..." screen
   - Send data to the backend for AI scoring
   - Display your results with scores for each domain

## Scoring Details

### Critical Thinking Score (0-100)
- **Accuracy** (40%): Logic challenges and text input answers
- **Bias Detection** (20%): Identifying cognitive biases
- **Cognitive Reflection** (20%): Harder reasoning puzzles
- **Justification Quality** (20%): AI-scored explanation quality
  - Clarity (0-3): Clear, concise language
  - Depth (0-3): Understanding beyond surface intuition
  - Logical Structure (0-4): Premises and conclusion linkage

### Memory Efficiency Score (0-100)
- **Immediate Recall Accuracy**: % of words recalled immediately
- **Retention Curve**: Ratio of delayed to immediate recall
- **Average Recall Time**: Mean seconds per word recalled
- Formula: `(Accuracy × Retention Curve) ÷ (Average Recall Time / 10)`

### Creativity Score (0-100)
- **Fluency** (30%): Number of unique ideas
- **Flexibility** (25%): Range of conceptual categories
- **Originality** (25%): Rarity of ideas vs dataset baseline
- **Refinement Gain** (20%): Quality improvement in refined idea

## Troubleshooting

### Backend Connection Issues

**Error: "Error scoring assessment: Connection refused"**
- Ensure backend is running: `npm start` in the `backend/` directory
- Check that port 3000 is not in use: `netstat -an | grep 3000`
- For physical devices, verify you're using the correct IP address

**Error: "HF_TOKEN not found"**
- Verify `.env` file exists in `backend/` directory
- Check that `HF_TOKEN` is set correctly
- Restart the backend server after updating `.env`

### API Token Issues

**Error: "Invalid API token"**
- Generate a new token from https://huggingface.co/settings/tokens
- Make sure the token has the necessary permissions
- Update `.env` and restart the backend

### Scoring Failures

If scoring fails, the app will use default scores (70.0) and continue. Check:
- Backend logs for error messages
- Network connectivity between app and backend
- Hugging Face API status

## API Response Examples

### Successful Justification Scoring
```json
{
  "clarity": 2,
  "depth": 2,
  "logical_structure": 3,
  "total": 7.0
}
```

### Successful Creativity Scoring
```json
{
  "fluency": 8,
  "flexibility": 7,
  "originality": 6,
  "refinement_gain": 7,
  "total": 70
}
```

### Successful Memory Scoring
```json
{
  "immediateRecallAccuracy": 70,
  "retentionCurve": 70,
  "averageRecallTime": 2.0,
  "total": 75
}
```

## Development Notes

### Adding New Scoring Endpoints

To add a new scoring endpoint:

1. Create a new POST endpoint in `backend/server.js`
2. Add corresponding method in `lib/services/scoring_service.dart`
3. Call the service method from the assessment screen
4. Display results in the results screen

### Customizing Scoring Weights

Weights are defined in:
- **Critical Thinking**: `lib/models/assessmentResult.dart` (weights map)
- **Creativity**: `backend/server.js` (CSS formula)
- **Memory**: `backend/server.js` (MES formula)

### Testing Without Backend

For testing without a running backend, the `ScoringService` returns default scores:
- Critical Thinking: 70.0
- Memory: 70.0
- Creativity: 50.0

## Performance Considerations

- Scoring requests timeout after 30 seconds
- Large text inputs may take longer to score
- Consider caching results for repeated assessments
- Monitor Hugging Face API rate limits

## Security Notes

- Never commit `.env` file to version control
- Use environment variables for all sensitive data
- Validate all user inputs before sending to API
- Consider implementing rate limiting for production
