import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { HfInference } from '@huggingface/inference';

const app = express();
const client = new HfInference(process.env.HF_TOKEN, {
  apiUrl: 'https://router.huggingface.co/hf-inference'
});

app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Score justification text using AI
app.post('/score-justification', async (req, res) => {
  try {
    const { question, userAnswer } = req.body;

    if (!question || !userAnswer) {
      return res.status(400).json({ error: 'Missing question or userAnswer' });
    }

    const chatCompletion = await client.chatCompletion({
      model: 'openai/gpt-oss-20b:cheapest',
      messages: [
        {
          role: 'system',
          content:
            'You are an AI grader. Respond ONLY with valid JSON. No explanations, no extra text. JSON keys must be: clarity, depth, logical_structure. All values are integers from 0-10.',
        },
        {
          role: 'user',
          content: `
Question: ${question}
User answer: ${userAnswer}

Evaluation rubric (0–10):
Clarity (0–3): Is reasoning stated in clear, concise language?
Depth (0–3): Does reasoning show understanding beyond surface intuition?
Logical structure (0–4): Are premises and conclusion linked logically?

Reply ONLY with JSON in this format:
{
  "clarity": <number 0-3>,
  "depth": <number 0-3>,
  "logical_structure": <number 0-4>
}
          `,
        },
      ],
    });

    const responseText = chatCompletion.choices[0].message.content;
    const scores = JSON.parse(responseText);

    // Validate scores
    if (
      typeof scores.clarity !== 'number' ||
      typeof scores.depth !== 'number' ||
      typeof scores.logical_structure !== 'number'
    ) {
      throw new Error('Invalid score format from AI');
    }

    // Calculate total (0-10)
    const total = (scores.clarity + scores.depth + scores.logical_structure) / 10;

    res.json({
      clarity: scores.clarity,
      depth: scores.depth,
      logical_structure: scores.logical_structure,
      total: Math.round(total * 100) / 100,
    });
  } catch (error) {
    console.error('Error scoring justification:', error);
    res.status(500).json({ error: error.message });
  }
});

// Score creativity ideas using AI
app.post('/score-creativity', async (req, res) => {
  try {
    const { ideas, refinedIdea } = req.body;

    if (!ideas || !Array.isArray(ideas)) {
      return res.status(400).json({ error: 'Missing or invalid ideas array' });
    }

    const chatCompletion = await client.chatCompletion({
      model: 'openai/gpt-oss-20b:cheapest',
      messages: [
        {
          role: 'system',
          content:
            'You are a creativity evaluator. Respond ONLY with valid JSON. No explanations, no extra text. JSON keys must be: fluency, flexibility, originality, refinement_gain. All values are integers from 0-10.',
        },
        {
          role: 'user',
          content: `
User's creative ideas for uses of a brick:
${ideas.map((idea, i) => `${i + 1}. ${idea}`).join('\n')}

${refinedIdea ? `Refined idea: ${refinedIdea}` : ''}

Evaluate based on:
Fluency (0–10): Number and diversity of ideas (count of valid unique ideas)
Flexibility (0–10): Range of conceptual categories covered
Originality (0–10): Rarity and uniqueness of ideas
Refinement Gain (0–10): Quality improvement if refined idea provided, else 0

Reply ONLY with JSON in this format:
{
  "fluency": <number 0-10>,
  "flexibility": <number 0-10>,
  "originality": <number 0-10>,
  "refinement_gain": <number 0-10>
}
          `,
        },
      ],
    });

    const responseText = chatCompletion.choices[0].message.content;
    const scores = JSON.parse(responseText);

    // Validate scores
    if (
      typeof scores.fluency !== 'number' ||
      typeof scores.flexibility !== 'number' ||
      typeof scores.originality !== 'number' ||
      typeof scores.refinement_gain !== 'number'
    ) {
      throw new Error('Invalid score format from AI');
    }

    // Calculate weighted total (0-100)
    const total =
      scores.fluency * 0.3 +
      scores.flexibility * 0.25 +
      scores.originality * 0.25 +
      scores.refinement_gain * 0.2;

    res.json({
      fluency: scores.fluency,
      flexibility: scores.flexibility,
      originality: scores.originality,
      refinement_gain: scores.refinement_gain,
      total: Math.round(total),
    });
  } catch (error) {
    console.error('Error scoring creativity:', error);
    res.status(500).json({ error: error.message });
  }
});

// Score memory efficiency using AI
app.post('/score-memory', async (req, res) => {
  try {
    const { immediateRecallAccuracy, retentionCurve, averageRecallTime } = req.body;
    
    // Debug logging
    console.log('MEMORY SCORING REQUEST:');
    console.log(`Immediate Recall Accuracy: ${immediateRecallAccuracy}`);
    console.log(`Retention Curve: ${retentionCurve}`);
    console.log(`Average Recall Time: ${averageRecallTime}`);

    if (
      typeof immediateRecallAccuracy !== 'number' ||
      typeof retentionCurve !== 'number' ||
      typeof averageRecallTime !== 'number'
    ) {
      return res.status(400).json({ error: 'Missing or invalid metrics' });
    }

    // Calculate MES using the formula: (Accuracy × Retention Curve Fit) ÷ Average Recall Time
    // Handle edge cases:
    // - If immediateRecallAccuracy is 0, the score should be 0
    // - If retentionCurve is 0, the score should be very low
    // - If averageRecallTime is 0, use a small value to avoid division by zero
    
    // First check if user recalled any words at all
    if (immediateRecallAccuracy <= 0) {
      return res.json({
        immediateRecallAccuracy: 0,
        retentionCurve: 0,
        averageRecallTime: averageRecallTime || 10,
        total: 0, // Zero score if nothing recalled
      });
    }
    
    // Safe averageRecallTime to avoid division by zero
    const safeRecallTime = averageRecallTime <= 0 ? 10 : averageRecallTime;
    
    // Calculate MES
    const mes = (immediateRecallAccuracy * retentionCurve) / (safeRecallTime / 10);
    const normalizedMES = Math.min(100, Math.max(0, mes));
    
    // Debug logging for result
    console.log('MEMORY SCORING RESULT:');
    console.log(`Raw MES: ${mes}`);
    console.log(`Normalized MES: ${normalizedMES}`);

    res.json({
      immediateRecallAccuracy: Math.round(immediateRecallAccuracy),
      retentionCurve: Math.round(retentionCurve),
      averageRecallTime: Math.round(averageRecallTime * 100) / 100,
      total: Math.round(normalizedMES),
    });
  } catch (error) {
    console.error('Error scoring memory:', error);
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Rheto Scoring API running on port ${PORT}`);
});
