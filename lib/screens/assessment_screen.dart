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
                  label: Text("Critical Thinking"),
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
                  label: Text("Memory"),
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
                  label: Text("Creativity"),
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
              child: Text("Start"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF008000),
                textStyle: Theme.of(context).textTheme.headlineSmall,
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
            creativityData = {}; // Will be set by callback
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
          onReturnHome: () {
            Navigator.pop(context);
          },
        );
      default:
        return Center(child: Text("The fuck are you doing here?"));
    }
  }

  Widget _buildScoringScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
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
      print('Error during scoring: $e');
      setState(() {
        isScoring = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error scoring assessment: $e')));
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
          if (question.acceptableAnswers?.any((acceptable) => acceptable.toLowerCase().trim() == normalizedAnswer) ?? false) {
            correctAnswers++;
          }
        }
      }
    }
    
    // Calculate simple score (0-100)
    double simpleScore = totalQuestions > 0 ? (correctAnswers / totalQuestions) * 100 : 50.0;

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
          // Find the reflection question from the questions list
          final reflectionQ = criticalThinkingAnswers.entries
              .where((e) => e.key == selectedReflectionId)
              .firstOrNull;
          
          if (reflectionQ != null) {
            reflectionAnswer = reflectionQ.value.toString();
            // Get the question text
            reflectionQuestion = selectedReflectionId;
          }
        }
        
        final scores = await ScoringService.scoreJustification(
          question: 'Explain your reasoning',
          userAnswer: justificationText,
          reflectionQuestion: reflectionQuestion,
          reflectionAnswer: reflectionAnswer,
        );
        final justificationScore = scores['total'] ?? 70.0;
        // Weight: 80% simple score, 20% justification
        simpleScore = (simpleScore * 0.8) + (justificationScore * 0.2);
      } catch (e) {
        print('Error scoring justification: $e');
      }
    }

    return simpleScore;
  }

  Future<double> _scoreMemory() async {
    // Get memory metrics from collected data
    // If no data available, use zeros to ensure a low score
    double immediateRecallAccuracy = memoryData['immediateRecallAccuracy'] ?? 0.0;
    double retentionCurve = memoryData['retentionCurve'] ?? 0.0;
    double averageRecallTime = memoryData['averageRecallTime'] ?? 10.0; // High recall time = lower score
    
    // Debug logging for memory scoring
    print("ASSESSMENT MEMORY SCORING:");
    print("Memory Data: $memoryData");
    print("Immediate Recall Accuracy: $immediateRecallAccuracy");
    print("Retention Curve: $retentionCurve");
    print("Average Recall Time: $averageRecallTime");

    try {
      final scores = await ScoringService.scoreMemory(
        immediateRecallAccuracy: immediateRecallAccuracy,
        retentionCurve: retentionCurve,
        averageRecallTime: averageRecallTime,
      );
      return (scores['total'] ?? 0.0).toDouble();
    } catch (e) {
      print('Error scoring memory: $e');
      // Calculate score locally if API fails
      if (immediateRecallAccuracy <= 0) return 0.0;
      
      // Use the memory efficiency score formula from the guide
      final safeRecallTime = averageRecallTime <= 0 ? 10.0 : averageRecallTime;
      final score = (immediateRecallAccuracy * retentionCurve) / (safeRecallTime / 10);
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
      return (scores['total'] ?? 0.0).toDouble();
    } catch (e) {
      print('Error scoring creativity: $e');
      
      // Calculate a basic score based on number of ideas and refinement
      final ideasScore = ideas.isEmpty ? 0.0 : (ideas.length * 5).clamp(0.0, 50.0);
      final refinementScore = refinedIdea.isEmpty ? 0.0 : 20.0;
      return (ideasScore + refinementScore).clamp(0.0, 100.0);
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
