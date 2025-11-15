import 'package:shared_preferences/shared_preferences.dart';

class ScoreStorageService {
  static const String _criticalThinkingKey = 'critical_thinking_score';
  static const String _memoryKey = 'memory_score';
  static const String _creativityKey = 'creativity_score';
  static const String _hasCompletedAssessmentKey = 'has_completed_assessment';

  // Save scores after assessment
  static Future<void> saveScores({
    required double criticalThinkingScore,
    required double memoryScore,
    required double creativityScore,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_criticalThinkingKey, criticalThinkingScore);
    await prefs.setDouble(_memoryKey, memoryScore);
    await prefs.setDouble(_creativityKey, creativityScore);
    await prefs.setBool(_hasCompletedAssessmentKey, true);
  }

  // Get saved scores
  static Future<Map<String, double>> getScores() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'criticalThinking': prefs.getDouble(_criticalThinkingKey) ?? 0.0,
      'memory': prefs.getDouble(_memoryKey) ?? 0.0,
      'creativity': prefs.getDouble(_creativityKey) ?? 0.0,
    };
  }

  // Check if user has completed assessment
  static Future<bool> hasCompletedAssessment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedAssessmentKey) ?? false;
  }

  // Clear scores (for testing or reset)
  static Future<void> clearScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_criticalThinkingKey);
    await prefs.remove(_memoryKey);
    await prefs.remove(_creativityKey);
    await prefs.remove(_hasCompletedAssessmentKey);
  }
}
