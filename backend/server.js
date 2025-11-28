import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import { dirname } from 'path';
import express from 'express';
import cors from 'cors';
import { HfInference } from '@huggingface/inference';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

dotenv.config({ path: `${__dirname}/../.env` });

const app = express();

if (!process.env.HF_TOKEN) {
  console.error('ERROR: HF_TOKEN environment variable is not set!');
  console.error('Please add HF_TOKEN to your .env file');
  process.exit(1);
}

const client = new HfInference(process.env.HF_TOKEN, {
  apiUrl: 'https://router.huggingface.co/hf-inference'
});

app.use(cors());
app.use(express.json());

function parseAIResponse(responseText) {
  try {
    return JSON.parse(responseText);
  } catch (parseError) {
    const jsonMatch = responseText.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0]);
    }
    throw new Error('Could not parse JSON from AI response');
  }
}

function validateScores(scores, expectedKeys, maxScore = 5) {
  for (const key of expectedKeys) {
    if (typeof scores[key] !== 'number') {
      throw new Error(`Invalid score format: ${key} is not a number`);
    }
    scores[key] = Math.max(0, Math.min(maxScore, Math.round(scores[key])));
  }
}

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

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
          content: 'You are a strict AI grader with high standards. Be critical and demanding. Respond ONLY with valid JSON. No explanations, no extra text. JSON keys must be: clarity, depth, logical_structure. All values are integers from 0-10. Most answers should score below 7.',
        },
        {
          role: 'user',
          content: `Question: ${question}\nUser answer: ${userAnswer}\n\nGrade this answer STRICTLY on:\n- Clarity (0-10): Is it crystal clear? Deduct heavily for any ambiguity or vagueness. Most answers get 3-6.\n- Depth (0-10): Is it thorough and insightful? Deduct heavily for surface-level answers. Most answers get 2-5.\n- Logical Structure (0-10): Is the reasoning sound and well-organized? Be strict. Most answers get 0-2.\n\nBe harsh. Most answers should score low. Respond with JSON: {"clarity": X, "depth": X, "logical_structure": X}`,
        },
      ],
    });

    const scores = parseAIResponse(chatCompletion.choices[0].message.content);
    validateScores(scores, ['clarity', 'depth', 'logical_structure'], 10);

    const total = Math.round((scores.clarity + scores.depth + scores.logical_structure) / 3 * 10);

    res.json({
      clarity: scores.clarity,
      depth: scores.depth,
      logical_structure: scores.logical_structure,
      total,
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
          content: 'You are a strict creativity evaluator with high standards. Be critical and demanding. Respond ONLY with valid JSON. No explanations, no extra text. JSON keys must be: fluency, flexibility, originality, refinement_quality. All values are integers from 0-10. Most answers should score below 6.',
        },
        {
          role: 'user',
          content: `User's creative ideas:\n${ideas.map((idea, i) => `${i + 1}. ${idea}`).join('\n')}\n${refinedIdea ? `\nRefined/synthesized idea: ${refinedIdea}` : '\nNo refined idea provided.'}\n\nEvaluate STRICTLY on:\n- Fluency (0-10): Number and variety of ideas\n- Flexibility (0-10): Diversity of idea categories\n- Originality (0-10): How novel and unique the ideas are\n- Refinement Quality (0-10): Quality of the refined/synthesized idea${refinedIdea ? '' : ' (score 0 if none provided)'}\n\nBe very critical. Reply ONLY with JSON: {"fluency": X, "flexibility": X, "originality": X, "refinement_quality": X}`,
        },
      ],
    });

    const scores = parseAIResponse(chatCompletion.choices[0].message.content);
    validateScores(scores, ['fluency', 'flexibility', 'originality', 'refinement_quality']);

    const total = Math.round(
      scores.fluency * 0.3 +
      scores.flexibility * 0.25 +
      scores.originality * 0.25 +
      scores.refinement_quality * 0.2
    );

    res.json({
      fluency: scores.fluency,
      flexibility: scores.flexibility,
      originality: scores.originality,
      refinement_gain: scores.refinement_quality,
      total,
    });
  } catch (error) {
    console.error('Error scoring creativity:', error);
    res.status(500).json({ error: error.message });
  }
});

// Score memory efficiency
app.post('/score-memory', async (req, res) => {
  try {
    const { immediateRecallAccuracy, retentionCurve, averageRecallTime } = req.body;

    if (
      typeof immediateRecallAccuracy !== 'number' ||
      typeof retentionCurve !== 'number' ||
      typeof averageRecallTime !== 'number'
    ) {
      return res.status(400).json({ error: 'Missing or invalid metrics' });
    }

    // If no recall, score is 0
    if (immediateRecallAccuracy <= 0) {
      return res.json({
        immediateRecallAccuracy: 0,
        retentionCurve: 0,
        averageRecallTime: averageRecallTime || 10,
        total: 0,
      });
    }

    // Calculate MES: (Accuracy × Retention Curve) ÷ (Average Recall Time / 10)
    const safeRecallTime = averageRecallTime <= 0 ? 10 : averageRecallTime;
    const mes = (immediateRecallAccuracy * retentionCurve) / (safeRecallTime / 10);
    const total = Math.round(Math.min(100, Math.max(0, mes)));

    res.json({
      immediateRecallAccuracy: Math.round(immediateRecallAccuracy),
      retentionCurve: Math.round(retentionCurve),
      averageRecallTime: Math.round(averageRecallTime * 100) / 100,
      total,
    });
  } catch (error) {
    console.error('Error scoring memory:', error);
    res.status(500).json({ error: error.message });
  }
});

// Generate a unique micro-story with embedded contradictions
app.post('/generate-contradiction-story', async (req, res) => {
  try {
    const { difficulty = 'medium', previousStories = [] } = req.body;

    // Map difficulty to contradiction count and complexity
    const difficultyConfig = {
      easy: { minContradictions: 2, maxContradictions: 2, complexity: 'surface-level' },
      medium: { minContradictions: 2, maxContradictions: 3, complexity: 'multi-layered' },
      hard: { minContradictions: 3, maxContradictions: 4, complexity: 'philosophical' },
    };

    const config = difficultyConfig[difficulty] || difficultyConfig.medium;
    const contradictionCount = Math.floor(
      Math.random() * (config.maxContradictions - config.minContradictions + 1) +
        config.minContradictions
    );

    // Contradiction types to vary across iterations
    const contradictionTypes = [
      'temporal',
      'causal',
      'motivation_inconsistency',
      'hidden_assumption_shift',
      'logical_impossibility',
    ];

    // Randomly select different contradiction types
    const selectedTypes = [];
    for (let i = 0; i < contradictionCount; i++) {
      selectedTypes.push(
        contradictionTypes[Math.floor(Math.random() * contradictionTypes.length)]
      );
    }

    const chatCompletion = await client.chatCompletion({
      model: 'openai/gpt-oss-20b:cheapest',
      messages: [
        {
          role: 'system',
          content: `You are a creative writer specializing in crafting short narratives with hidden logical contradictions. 
Your stories are 60-90 seconds to read (approximately 150-250 words). 
Each story must contain exactly ${contradictionCount} subtle contradictions of types: ${selectedTypes.join(', ')}.
The contradictions should be hidden but detectable by careful readers.
Respond ONLY with valid JSON. No explanations, no extra text.
JSON format: {"story": "...", "contradictions": [{"type": "...", "description": "..."}, ...], "difficulty": "${difficulty}"}`,
        },
        {
          role: 'user',
          content: `Generate a unique micro-story (60-90 seconds read time) with exactly ${contradictionCount} contradictions of these types: ${selectedTypes.join(', ')}.
The contradictions should be:
- Subtle but detectable (not obvious)
- Varied in type (temporal, causal, motivation, assumption, logical impossibility)
- Woven naturally into the narrative
- Challenging for critical thinkers

Make the story engaging and realistic. Here are previous stories to avoid repetition: ${
            previousStories.length > 0
              ? previousStories.slice(-3).join(' | ')
              : 'None'
          }

Respond with JSON: {"story": "...", "contradictions": [{"type": "temporal/causal/motivation_inconsistency/hidden_assumption_shift/logical_impossibility", "description": "..."}, ...], "difficulty": "${difficulty}"}`,
        },
      ],
    });

    const result = parseAIResponse(chatCompletion.choices[0].message.content);

    if (!result.story || !Array.isArray(result.contradictions)) {
      throw new Error('Invalid story format from AI');
    }

    res.json({
      story: result.story,
      contradictions: result.contradictions,
      difficulty: difficulty,
      expectedContradictionCount: contradictionCount,
    });
  } catch (error) {
    console.error('Error generating contradiction story:', error);
    res.status(500).json({ error: error.message });
  }
});

// Score contradiction detection and justification
app.post('/score-contradictions', async (req, res) => {
  try {
    const { story, detectedContradictions, justification, expectedContradictions } = req.body;

    if (!story || !Array.isArray(detectedContradictions) || !justification) {
      return res.status(400).json({
        error: 'Missing story, detectedContradictions array, or justification',
      });
    }

    const chatCompletion = await client.chatCompletion({
      model: 'openai/gpt-oss-20b:cheapest',
      messages: [
        {
          role: 'system',
          content: `You are a strict critical thinking evaluator. Respond ONLY with valid JSON. No explanations, no extra text.
JSON keys must be: accuracy_rate, bias_detection_rate, cognitive_reflection, justification_quality.
Values are point awards: accuracy_rate (0-3), bias_detection_rate (0-2), cognitive_reflection (0-1), justification_quality (0-4).
Be harsh and critical.`,
        },
        {
          role: 'user',
          content: `Story: "${story}"

User detected these contradictions: ${detectedContradictions.map((c) => `"${c}"`).join(', ')}

User's justification: "${justification}"

Expected contradictions in the story: ${expectedContradictions ? expectedContradictions.join(', ') : 'Not specified'}

Award points based on performance:

ACCURACY RATE (0-3 points):
- 3 points: User correctly identified all or nearly all real contradictions
- 2 points: User identified most contradictions, minor misses
- 1 point: User identified some contradictions but missed major ones
- 0 points: User missed most or all contradictions

BIAS DETECTION RATE (0-2 points):
- 2 points: User caught assumption shifts, hidden biases, or logical fallacies
- 1 point: User showed some awareness of bias but incomplete
- 0 points: User missed biases entirely

COGNITIVE REFLECTION (0-1 point):
- 1 point: User showed signs of questioning first instinct (e.g., "I initially thought... but...")
- 0 points: User provided surface-level analysis without reflection

JUSTIFICATION QUALITY (0-4 points):
- 4 points: Explanation is clear, well-structured, logically coherent, and insightful
- 3 points: Good explanation with minor clarity issues
- 2 points: Adequate explanation but somewhat vague or incomplete
- 1 point: Weak explanation with significant gaps
- 0 points: Incoherent or unrelated explanation

Respond ONLY with JSON: {"accuracy_rate": X, "bias_detection_rate": X, "cognitive_reflection": X, "justification_quality": X}`,
        },
      ],
    });

    const scores = parseAIResponse(chatCompletion.choices[0].message.content);
    
    // Validate and clamp point values to their max ranges
    scores.accuracy_rate = Math.max(0, Math.min(3, Math.round(scores.accuracy_rate)));
    scores.bias_detection_rate = Math.max(0, Math.min(2, Math.round(scores.bias_detection_rate)));
    scores.cognitive_reflection = Math.max(0, Math.min(1, Math.round(scores.cognitive_reflection)));
    scores.justification_quality = Math.max(0, Math.min(4, Math.round(scores.justification_quality)));

    // Calculate total points (max 10)
    const totalPoints = scores.accuracy_rate + scores.bias_detection_rate + scores.cognitive_reflection + scores.justification_quality;
    // Convert to 0-100 scale for activity score display
    const total = Math.round((totalPoints / 10) * 100);

    res.json({
      accuracy_rate: scores.accuracy_rate,
      bias_detection_rate: scores.bias_detection_rate,
      cognitive_reflection: scores.cognitive_reflection,
      justification_quality: scores.justification_quality,
      total_points: totalPoints,
      total: total,
    });
  } catch (error) {
    console.error('Error scoring contradictions:', error);
    res.status(500).json({ error: error.message });
  }
});

// ============================================================================
// CONSEQUENCE ENGINE ENDPOINTS
// ============================================================================

// Generate an absurd premise for Consequence Engine
app.post('/generate-premise', async (req, res) => {
  try {
    const { previousPremises = [] } = req.body;

    const premisePrompt = `Generate ONE absurd, creative premise for a "Consequence Engine" game. The premise should be:
- Physically impossible or highly unusual (e.g., "Gravity only works on Tuesdays", "Plants can now walk slowly")
- Specific enough to trace consequences from (not vague)
- Interesting enough to inspire creative thinking across domains
- NOT similar to: ${previousPremises.length > 0 ? previousPremises.join(', ') : 'none yet'}

Return ONLY the premise as a single sentence, no quotes, no explanation.`;

    let chatCompletion;
    try {
      // Try with :cheapest first
      chatCompletion = await client.chatCompletion({
        model: 'openai/gpt-oss-20b:cheapest',
        messages: [
          {
            role: 'system',
            content: 'You are a creative premise generator. Generate absurd but specific premises. Respond with ONLY the premise, nothing else.',
          },
          {
            role: 'user',
            content: premisePrompt,
          },
        ],
      });
    } catch (fallbackError) {
      // Fallback to base model without :cheapest
      console.warn('Falling back to base model without :cheapest', fallbackError.message);
      chatCompletion = await client.chatCompletion({
        model: 'openai/gpt-oss-20b',
        messages: [
          {
            role: 'system',
            content: 'You are a creative premise generator. Generate absurd but specific premises. Respond with ONLY the premise, nothing else.',
          },
          {
            role: 'user',
            content: premisePrompt,
          },
        ],
      });
    }

    const premise = chatCompletion.choices[0].message.content.trim();

    res.json({ premise });
  } catch (error) {
    console.error('Error generating premise:', error);
    res.status(500).json({ error: error.message });
  }
});

// Score a consequence chain
app.post('/score-consequences', async (req, res) => {
  try {
    const { premise, chain, chainIndex = 1 } = req.body;

    if (!premise || !chain || !Array.isArray(chain) || chain.length === 0) {
      return res.status(400).json({ error: 'Missing premise or chain' });
    }

    // chain is an array of 4 consequences: [personal, social, economic, ecological]
    const chainText = chain.map((c, i) => `${i + 1}. ${c}`).join('\n');

    const scoringPrompt = `You are evaluating a creative consequence chain for a game called "Consequence Engine".

PREMISE: "${premise}"

CONSEQUENCE CHAIN (Chain #${chainIndex}):
${chainText}

Evaluate this chain on FOUR metrics (each 0-5 points):

1. FLUENCY (0-5): Did they produce enough quality ideas? 
   - 5 pts: All 4 consequences are well-developed and complete
   - 3-4 pts: 3-4 consequences present, mostly complete
   - 1-2 pts: Incomplete or sparse ideas
   - 0 pts: Barely any content

2. FLEXIBILITY (0-5): Did they jump between different domains?
   - 5 pts: Hit all 4 required domains (Personal → Social → Economic → Ecological) with clear transitions
   - 3-4 pts: Hit 3 domains with some transitions
   - 1-2 pts: Stuck in 1-2 domains mostly
   - 0 pts: Only one domain

3. ORIGINALITY (0-5): Did they surprise you? (Avoid clichés)
   - 5 pts: Highly unexpected, creative, novel ideas (no obvious answers)
   - 3-4 pts: Creative with some predictable elements
   - 1-2 pts: Mostly predictable/cliché
   - 0 pts: Very obvious, boring answers

4. REFINEMENT GAIN (0-5): Does the story flow and connect?
   - 5 pts: Masterpiece - final consequence weaves everything together perfectly, callbacks to earlier ideas
   - 3-4 pts: Strong flow with some connections between steps
   - 1-2 pts: Loose connections, some flow issues
   - 0 pts: No connection between ideas

Respond ONLY with JSON: {"fluency": X, "flexibility": X, "originality": X, "refinement_gain": X}`;

    const chatCompletion = await client.chatCompletion({
      model: 'openai/gpt-oss-20b:cheapest',
      messages: [
        {
          role: 'system',
          content:
            'You are a strict creative evaluator. Be critical and demanding. Respond ONLY with valid JSON. No explanations, no extra text.',
        },
        {
          role: 'user',
          content: scoringPrompt,
        },
      ],
    });

    const scores = parseAIResponse(chatCompletion.choices[0].message.content);
    validateScores(scores, ['fluency', 'flexibility', 'originality', 'refinement_gain'], 5);

    // Calculate total score (0-100)
    const totalPoints = scores.fluency + scores.flexibility + scores.originality + scores.refinement_gain;
    const total = Math.round((totalPoints / 20) * 100);

    res.json({
      fluency: scores.fluency,
      flexibility: scores.flexibility,
      originality: scores.originality,
      refinement_gain: scores.refinement_gain,
      total_points: totalPoints,
      total: total,
    });
  } catch (error) {
    console.error('Error scoring consequences:', error);
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Rheto Scoring API running on port ${PORT}`);
});

