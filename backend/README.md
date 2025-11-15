# Rheto Scoring API

AI-powered scoring API for Rheto assessment using Hugging Face Inference API.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create `.env` file with your Hugging Face token:
```
HF_TOKEN=your_hf_token_here
PORT=3000
```

3. Start the server:
```bash
npm start
```

For development with auto-reload:
```bash
npm run dev
```

## Endpoints

### POST /score-justification
Score a justification text using AI.

**Request:**
```json
{
  "question": "Explain your reasoning",
  "userAnswer": "User's explanation text"
}
```

**Response:**
```json
{
  "clarity": 2,
  "depth": 2,
  "logical_structure": 3,
  "total": 7.0
}
```

### POST /score-creativity
Score creativity ideas using AI.

**Request:**
```json
{
  "ideas": ["idea1", "idea2", "idea3"],
  "refinedIdea": "refined version of an idea"
}
```

**Response:**
```json
{
  "fluency": 8,
  "flexibility": 7,
  "originality": 6,
  "refinement_gain": 7,
  "total": 70
}
```

### POST /score-memory
Score memory efficiency using provided metrics.

**Request:**
```json
{
  "immediateRecallAccuracy": 70.0,
  "retentionCurve": 0.7,
  "averageRecallTime": 2.0
}
```

**Response:**
```json
{
  "immediateRecallAccuracy": 70,
  "retentionCurve": 70,
  "averageRecallTime": 2.0,
  "total": 75
}
```

### GET /health
Health check endpoint.

**Response:**
```json
{
  "status": "ok"
}
```

## Environment Variables

- `HF_TOKEN`: Your Hugging Face API token (required)
- `PORT`: Server port (default: 3000)

## Notes

- The API uses the Hugging Face Inference API with the `openai/gpt-oss-20b:cheapest` model
- All scoring endpoints return scores normalized to 0-100 scale
- Error responses include a descriptive error message
