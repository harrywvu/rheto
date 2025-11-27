import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ScoreStorageService {
  static const String _ctMetricsKey = 'critical_thinking_metrics';
  static const String _memMetricsKey = 'memory_metrics';
  static const String _crMetricsKey = 'creativity_metrics';
  static const String _hasCompletedAssessmentKey = 'has_completed_assessment';

  // Save metrics after assessment (overall score is calculated from metrics)
  static Future<void> saveMetrics({
    required Map<String, double> criticalThinkingMetrics,
    required Map<String, double> memoryMetrics,
    required Map<String, double> creativityMetrics,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ctMetricsKey, jsonEncode(criticalThinkingMetrics));
    await prefs.setString(_memMetricsKey, jsonEncode(memoryMetrics));
    await prefs.setString(_crMetricsKey, jsonEncode(creativityMetrics));
    await prefs.setBool(_hasCompletedAssessmentKey, true);
  }

  // Get saved metrics
  static Future<Map<String, Map<String, double>>> getMetrics() async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, double> _parseMetrics(String? json) {
      if (json == null) return {};
      try {
        return Map<String, double>.from(
          (jsonDecode(json) as Map).map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ),
        );
      } catch (e) {
        return {};
      }
    }

    return {
      'criticalThinking': _parseMetrics(prefs.getString(_ctMetricsKey)),
      'memory': _parseMetrics(prefs.getString(_memMetricsKey)),
      'creativity': _parseMetrics(prefs.getString(_crMetricsKey)),
    };
  }

  // Get calculated overall scores from metrics
  static Future<Map<String, double>> getScores() async {
    final metrics = await getMetrics();

    double _calculateAverage(Map<String, double> metricMap) {
      if (metricMap.isEmpty) return 0.0;
      final sum = metricMap.values.reduce((a, b) => a + b);
      return sum / metricMap.length;
    }

    return {
      'criticalThinking': _calculateAverage(metrics['criticalThinking']!),
      'memory': _calculateAverage(metrics['memory']!),
      'creativity': _calculateAverage(metrics['creativity']!),
    };
  }

  // Check if user has completed assessment
  static Future<bool> hasCompletedAssessment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedAssessmentKey) ?? false;
  }

  // Clear all data (for testing or reset)
  static Future<void> clearScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ctMetricsKey);
    await prefs.remove(_memMetricsKey);
    await prefs.remove(_crMetricsKey);
    await prefs.remove(_hasCompletedAssessmentKey);
  }
}
