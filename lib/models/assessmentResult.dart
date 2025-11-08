import 'dart:convert';
import 'dart:io';

import 'package:rheto/models/question.dart';

class AssessmentResult {
  final String assessmentType;
  final Map<String, dynamic> answers;
  final double totalScore;
  final Map<String, double> subScores;
  final DateTime completedAt;

  AssessmentResult({
    required this.assessmentType,
    required this.answers,
    required this.totalScore,
    required this.subScores,
    required this.completedAt,
  });
}

class CriticalThinkingScorer {
  static Future <double> calculateScore(
    Map<String, dynamic> answers,
    List<Question> questions,
  ) async{
    // Weights from the spec
    const weights = {
      QuestionCategory.logic: 0.40,
      QuestionCategory.biasDetection: 0.20,
      QuestionCategory.cognitiveReflection: 0.20,
      QuestionCategory.justification: 0.20,
    };
    Map<QuestionCategory, int> correct = {};
    Map<QuestionCategory, int> total = {};

    for (var question in questions) {
      if (question.category == QuestionCategory.justification)
        continue; // Handle separately

      total[question.category] = (total[question.category] ?? 0) + 1;

      final userAnswer = answers[question.id];
      if (userAnswer == null) continue;

      bool isCorrect = false;

      if (question.type == QuestionType.multipleChoice) {
        isCorrect = userAnswer == question.correctAnswerIndex;
      } else if (question.type == QuestionType.textInput) {
        final normalizedAnswer = userAnswer.toString().toLowerCase().trim();
        isCorrect =
            question.acceptableAnswers?.any(
              (acceptable) =>
                  acceptable.toLowerCase().trim() == normalizedAnswer,
            ) ??
            false;
      }

      if (isCorrect) {
        correct[question.category] = (correct[question.category] ?? 0) + 1;
      }
    }

    double finalScore = 0.0;
    Map<QuestionCategory, double> categoryScores = {};

    correct.forEach((category, correctCount) {
      final totalCount = total[category] ?? 1;
      final percentage = (correctCount / totalCount) * 100;
      categoryScores[category] = percentage;
      finalScore += percentage * (weights[category] ?? 0);
    });

    // For now, justification is manually scored or uses a simple check
    // add AI-based scoring later
    if (answers.containsKey('justification_1')) {
      final justificationText = answers['justification_1'] as String;
      final justificationScore = await _scoreJustification(justificationText); // Add await
      categoryScores[QuestionCategory.justification] = justificationScore;
      finalScore += justificationScore * (weights[QuestionCategory.justification] ?? 0);
    }
  
    return finalScore;
  }

  static Future<double> _scoreJustification(String text) async {
    try {
      final scriptPath = r'c:\cross-platform-dev\rheto\lib\ai-scoring\nlp-reasoning-scoring.py';
      final payload = jsonEncode({
        'text': text,
        'reference': '' // Add reference text if you have it
      });
      
      final process = await Process.start(
        'python',
        [scriptPath],
        runInShell: true,
      );
      
      // Write JSON payload to stdin
      process.stdin.write(payload);
      await process.stdin.close();
      
      // Read stdout and stderr
      final outputFuture = process.stdout.transform(utf8.decoder).join();
      final errorFuture = process.stderr.transform(utf8.decoder).join();
      
      final output = await outputFuture;
      final error = await errorFuture;
      final exitCode = await process.exitCode;
      
      if (exitCode != 0) {
        print('Python script error: $error');
        return 60.0;
      }
      
      final trimmedOutput = output.trim();
      if (trimmedOutput.isEmpty) return 60.0;
      
      final Map<String, dynamic> parsed =
          jsonDecode(trimmedOutput) as Map<String, dynamic>;
      final num rawScore =
          (parsed['final_score'] ?? parsed['score'] ?? 0) as num;
      
      // Convert from 0-1 scale to 0-100 scale
      return (rawScore.toDouble()) * 100.0;
    } catch (e) {
        print('Exception in _scoreJustification: $e');
        return 60.0;
    }
  }
  
}
