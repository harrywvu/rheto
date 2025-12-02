import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rheto/screens/quiz_screen-critical-thinking.dart';
import 'quiz_screen-memory-booster.dart';
import 'quiz_screen_creativity.dart';
import 'results_screen.dart';
import 'package:rheto/services/scoring_service.dart';
import 'package:rheto/models/questions.dart';
import 'package:rheto/models/question.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<StatefulWidget> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  // startScreen = 0 : The initial screen for the assessment
  int currentStep = 0;

  // Store assessment data from each quiz
  Map<String, dynamic> criticalThinkingAnswers = {};
  Map<String, dynamic> memoryData = {};
  Map<String, dynamic> creativityData = {};

  // Store final scores
  double criticalThinkingScore = 0;
  double memoryScore = 0;
  double creativityScore = 0;
  bool isScoring = false;

  // Store individual metrics from scoring
  Map<String, double> criticalThinkingMetrics = {};
  Map<String, double> memoryMetrics = {};
  Map<String, double> creativityMetrics = {};

  Widget getStepWidget(int step) {
    switch (step) {
      case 0:
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                Text(
                  'Think of this as a checkup!',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontFamily: 'Ntype82-R'),
                ),
                Text(
                  'This is to establish your baseline cognitive profile across three domains:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontFamily: 'Lettera'),
                  textAlign: TextAlign.center,
                ),
              ],
            ),

            Column(
              spacing: 8,
              children: [
                Chip(
                  avatar: FaIcon(
                    FontAwesomeIcons.gears,
                    color: Color(0xFF74C0FC),
                    size: 20,
                  ),
                  label: Text(
                    "Critical Thinking",
                    style: const TextStyle(fontFamily: 'Lettera'),
                  ),
                  shape: Theme.of(context).chipTheme!.shape?.copyWith(
                    side: BorderSide(color: Color(0xFF74C0FC)),
                  ),
                ),

                Chip(
                  avatar: FaIcon(
                    FontAwesomeIcons.lightbulb,
                    color: Color(0xFFFFD43B),
                    size: 20,
                  ),
                  label: Text(
                    "Memory",
                    style: const TextStyle(fontFamily: 'Lettera'),
                  ),
                  shape: Theme.of(context).chipTheme!.shape?.copyWith(
                    side: BorderSide(color: Color(0xFFFFD43B)),
                  ),
                ),

                Chip(
                  avatar: FaIcon(
                    FontAwesomeIcons.squareShareNodes,
                    color: Color(0xFF63E6BE),
                    size: 20,
                  ),
                  label: Text(
                    "Creativity",
                    style: const TextStyle(fontFamily: 'Lettera'),
                  ),
                  shape: Theme.of(context).chipTheme!.shape?.copyWith(
                    side: BorderSide(color: Color(0xFF63E6BE)),
                  ),
                ),
              ],
            ),

            ElevatedButton(
              onPressed: () {
                // When pressed, the screen changes to the first activity.
                setState(() {
                  currentStep++;
                });
              },
              child: Text(
                "Start",
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontFamily: 'Ntype82-R'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008000),
              ),
            ),

            Text(
              "This won't take long! 😊",
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontFamily: 'Lettera'),
              textAlign: TextAlign.center,
            ),
          ],
        );
      case 1: // Critical Thinking Trainer
        return QuizScreen_Critical_Thinking(
          onComplete: () => {
            setState(() {
              currentStep++;
            }),
          },
          onDataCollected: (data) {
            criticalThinkingAnswers = data;
          },
        );
      case 2:
        return QuizScreenMemoryBooster(
          onComplete: () => {
            setState(() {
              currentStep++;
            }),
          },
          onDataCollected: (data) {
            memoryData = data;
          },
        );
      case 3:
        return QuizScreenCreativity(
          onComplete: () async {
            // Trigger scoring after creativity quiz
            await _performScoring();
          },
          onDataCollected: (data) {
            creativityData = data;
          },
        );
      case 4:
        // Scoring screen
        return _buildScoringScreen();
      case 5:
        // Results screen
        return ResultsScreen(
          criticalThinkingScore: criticalThinkingScore,
          memoryScore: memoryScore,
          creativityScore: creativityScore,
          criticalThinkingMetrics: criticalThinkingMetrics,
          memoryMetrics: memoryMetrics,
          creativityMetrics: creativityMetrics,
          onReturnHome: () {
            Navigator.pop(context);
          },
        );
      default:
        return Center(
          child: Text(
            "The fuck are you doing here?",
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontFamily: 'Lettera'),
          ),
        );
    }
  }

  Widget _buildScoringScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDA77F2)),
          ),
          SizedBox(height: 24),
          Text(
            'Analyzing your responses...',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontFamily: 'Lettera'),
          ),
        ],
      ),
    );
  }

  Future<void> _performScoring() async {
    setState(() {
      isScoring = true;
      currentStep = 4; // Show scoring screen
    });

    try {
      // Score critical thinking (using simple calculation + AI for justification)
      criticalThinkingScore = await _scoreCriticalThinking();

      // Score memory (using provided metrics)
      memoryScore = await _scoreMemory();

      // Score creativity (using AI)
      creativityScore = await _scoreCreativity();

      // Move to results screen
      setState(() {
        currentStep = 5;
        isScoring = false;
      });
    } catch (e) {
      setState(() {
        isScoring = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error scoring assessment: $e',
            style: const TextStyle(fontFamily: 'Lettera'),
          ),
        ),
      );
    }
  }

  Future<double> _scoreCriticalThinking() async {
    // Calculate score based on correct answers
    int totalQuestions = 0;
    int correctAnswers = 0;

    // Score logic questions
    for (var question in logicQuestions) {
      totalQuestions++;
      final userAnswer = criticalThinkingAnswers[question.id];
      if (userAnswer != null && userAnswer == question.correctAnswerIndex) {
        correctAnswers++;
      }
    }

    // Score bias detection questions
    for (var question in biasDetectionQuestions) {
      totalQuestions++;
      final userAnswer = criticalThinkingAnswers[question.id];
      if (userAnswer != null && userAnswer == question.correctAnswerIndex) {
        correctAnswers++;
      }
    }

    // Score cognitive reflection questions
    for (var question in cognitiveReflectionQuestions) {
      totalQuestions++;
      final userAnswer = criticalThinkingAnswers[question.id];
      if (userAnswer != null) {
        if (question.type == QuestionType.textInput) {
          final normalizedAnswer = userAnswer.toString().toLowerCase().trim();
          if (question.acceptableAnswers?.any(
                (acceptable) =>
                    acceptable.toLowerCase().trim() == normalizedAnswer,
              ) ??
              false) {
            correctAnswers++;
          }
        }
      }
    }

    // Calculate simple score (0-100)
    double simpleScore = totalQuestions > 0
        ? (correctAnswers / totalQuestions) * 100
        : 50.0;

    // Try to score justification with AI if available
    if (criticalThinkingAnswers.containsKey('justification_1')) {
      try {
        final justificationText =
            criticalThinkingAnswers['justification_1'] as String;

        // Get the selected reflection question and answer for context
        final selectedReflectionId =
            criticalThinkingAnswers['selectedReflectionQuestionId'] as String?;
        String? reflectionQuestion;
        String? reflectionAnswer;

        if (selectedReflectionId != null) {
          // Look up the selected reflection answer directly from the map
          final selectedAnswer = criticalThinkingAnswers[selectedReflectionId];
          if (selectedAnswer != null) {
            reflectionAnswer = selectedAnswer.toString();
            // Use the selectedReflectionId as the question identifier/context
            reflectionQuestion = selectedReflectionId;
          }
        }

        final scores = await ScoringService.scoreJustification(
          question: 'Explain your reasoning',
          userAnswer: justificationText,
          reflectionQuestion: reflectionQuestion,
          reflectionAnswer: reflectionAnswer,
        );

        // Extract individual metrics from AI scoring
        final clarity = (scores['clarity'] as num? ?? 0).toDouble();
        final depth = (scores['depth'] as num? ?? 0).toDouble();

        // Store metrics (convert from 0-10 scale to 0-100)
        criticalThinkingMetrics = {
          'Accuracy': ((simpleScore * 0.8) + (clarity * 10))
              .clamp(0, 100)
              .toDouble(),
          'Bias Detection': (depth * 10).clamp(0, 100).toDouble(),
          'Cognitive Reflection': simpleScore,
          'Justification Quality': (clarity * 10).clamp(0, 100).toDouble(),
        };

        final justificationScore = scores['total'] ?? 70.0;
        // Weight: 80% simple score, 20% justification
        simpleScore = (simpleScore * 0.8) + (justificationScore * 0.2);
      } catch (e) {
        // Fallback: use simple score for all metrics
        criticalThinkingMetrics = {
          'Accuracy': simpleScore,
          'Bias Detection': simpleScore,
          'Cognitive Reflection': simpleScore,
          'Justification Quality': simpleScore,
        };
      }
    } else {
      // No justification: use simple score for all metrics
      criticalThinkingMetrics = {
        'Accuracy': simpleScore,
        'Bias Detection': simpleScore,
        'Cognitive Reflection': simpleScore,
        'Justification Quality': simpleScore,
      };
    }

    return simpleScore;
  }

  Future<double> _scoreMemory() async {
    // Get memory metrics from collected data
    // If no data available, use zeros to ensure a low score
    double immediateRecallAccuracy =
        memoryData['immediateRecallAccuracy'] ?? 0.0;
    double retentionCurve = memoryData['retentionCurve'] ?? 0.0;
    double averageRecallTime =
        memoryData['averageRecallTime'] ??
        10.0; // High recall time = lower score

    try {
      final scores = await ScoringService.scoreMemory(
        immediateRecallAccuracy: immediateRecallAccuracy,
        retentionCurve: retentionCurve,
        averageRecallTime: averageRecallTime,
      );

      // Extract individual metrics
      memoryMetrics = {
        'Recall Accuracy': immediateRecallAccuracy.clamp(0, 100).toDouble(),
        'Recall Latency': ((100 - (averageRecallTime * 10).clamp(0, 100)).clamp(
          0,
          100,
        )).toDouble(),
        'Retention Curve': retentionCurve.clamp(0, 100).toDouble(),
        'Item Mastery': (scores['total'] ?? 0.0)
            .toDouble()
            .clamp(0, 100)
            .toDouble(),
      };

      return (scores['total'] ?? 0.0).toDouble();
    } catch (e) {
      // Calculate score locally if API fails
      if (immediateRecallAccuracy <= 0) {
        memoryMetrics = {
          'Recall Accuracy': 0,
          'Recall Latency': 0,
          'Retention Curve': 0,
          'Item Mastery': 0,
        };
        return 0.0;
      }

      // Use the memory efficiency score formula from the guide
      final safeRecallTime = averageRecallTime <= 0 ? 10.0 : averageRecallTime;
      final score =
          (immediateRecallAccuracy * retentionCurve) / (safeRecallTime / 10);

      memoryMetrics = {
        'Recall Accuracy': immediateRecallAccuracy.clamp(0, 100).toDouble(),
        'Recall Latency': ((100 - (safeRecallTime * 10).clamp(0, 100)).clamp(
          0,
          100,
        )).toDouble(),
        'Retention Curve': retentionCurve.clamp(0, 100).toDouble(),
        'Item Mastery': score.clamp(0, 100).toDouble(),
      };

      return score.clamp(0.0, 100.0);
    }
  }

  Future<double> _scoreCreativity() async {
    List<String> ideas = creativityData['ideas'] ?? [];
    String refinedIdea = creativityData['refinedIdea'] ?? '';

    try {
      final scores = await ScoringService.scoreCreativity(
        ideas: ideas,
        refinedIdea: refinedIdea.isNotEmpty ? refinedIdea : null,
      );

      // Extract individual metrics from AI scoring
      final fluency = (scores['fluency'] as num? ?? 0).toDouble();
      final flexibility = (scores['flexibility'] as num? ?? 0).toDouble();
      final originality = (scores['originality'] as num? ?? 0).toDouble();
      final refinement = (scores['refinement_gain'] as num? ?? 0).toDouble();

      // Store metrics (convert from 0-10 scale to 0-100)
      creativityMetrics = {
        'Fluency': (fluency * 10).clamp(0, 100).toDouble(),
        'Flexibility': (flexibility * 10).clamp(0, 100).toDouble(),
        'Originality': (originality * 10).clamp(0, 100).toDouble(),
        'Refinement Gain': (refinement * 10).clamp(0, 100).toDouble(),
      };

      return (scores['total'] ?? 0.0).toDouble();
    } catch (e) {
      // Calculate a basic score based on number of ideas and refinement
      final ideasScore = ideas.isEmpty
          ? 0.0
          : (ideas.length * 5).clamp(0.0, 50.0);
      final refinementScore = refinedIdea.isEmpty ? 0.0 : 20.0;
      final totalScore = (ideasScore + refinementScore).clamp(0.0, 100.0);

      // Fallback metrics
      creativityMetrics = {
        'Fluency': ideasScore.toDouble(),
        'Flexibility': (ideasScore * 0.8).toDouble(),
        'Originality': (ideasScore * 0.7).toDouble(),
        'Refinement Gain': refinementScore.toDouble(),
      };

      return totalScore;
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 70),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            // children is a list of widgets
            // 1st child of the column -> Return & subtitle screen
            Row(
              children: [
                // Press this to go back to home screen
                IconButton(
                  // iconSize: ,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back),
                ),

                Text(
                  'Initial Assessment',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontFamily: 'Ntype82-R'),
                ),
              ],
            ),

            SizedBox(height: 20),

            // Second child of the column -> Welcome and Onboaring with Proceed Button
            // This is the child widget that changes when the elevated button is clicked.
            Expanded(child: getStepWidget(currentStep)),
          ],
        ),
      ),
    );
  }
}
