import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'metrics_database.dart';

class ScoreStorageService {
  static const String _ctMetricsKey = 'critical_thinking_metrics';
  static const String _memMetricsKey = 'memory_metrics';
  static const String _crMetricsKey = 'creativity_metrics';
  static const String _hasCompletedAssessmentKey = 'has_completed_assessment';

  // Map display names to database column names
  static const Map<String, String> _displayToDbKey = {
    // Critical Thinking
    'Accuracy': 'accuracy_rate',
    'Bias Detection': 'bias_detection_rate',
    'Cognitive Reflection': 'cognitive_reflection',
    'Justification Quality': 'justification_quality',
    // Memory
    'Recall Accuracy': 'recall_accuracy',
    'Recall Latency': 'recall_latency',
    'Retention Curve': 'retention_curve',
    'Item Mastery': 'item_mastery',
    // Creativity
    'Fluency': 'fluency',
    'Flexibility': 'flexibility',
    'Originality': 'originality',
    'Refinement Gain': 'refinement_gain',
  };

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

    // Also persist to SQLite database for historical tracking
    await _insertSessionToDatabase(
      criticalThinkingMetrics,
      memoryMetrics,
      creativityMetrics,
    );
  }

  /// Insert a session into the SQLite database
  static Future<void> _insertSessionToDatabase(
    Map<String, double> ctMetrics,
    Map<String, double> memMetrics,
    Map<String, double> crMetrics,
  ) async {
    // Convert display names to database column names
    final dbMetrics = <String, double>{};

    void addMetrics(Map<String, double> metrics) {
      for (final entry in metrics.entries) {
        final dbKey = _displayToDbKey[entry.key];
        if (dbKey != null) {
          dbMetrics[dbKey] = entry.value;
        }
      }
    }

    addMetrics(ctMetrics);
    addMetrics(memMetrics);
    addMetrics(crMetrics);

    await MetricsDatabase.insertSession(dbMetrics);
  }

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

  static Future<Map<String, double>> getScores() async {
    final metrics = await getMetrics();

    // Critical Thinking: Weighted formula
    double _calculateCriticalThinking(Map<String, double> ctMetrics) {
      if (ctMetrics.isEmpty) return 0.0;
      final accuracy = ctMetrics['Accuracy'] ?? 0.0;
      final biasDetection = ctMetrics['Bias Detection'] ?? 0.0;
      final reflection = ctMetrics['Cognitive Reflection'] ?? 0.0;
      final justification = ctMetrics['Justification Quality'] ?? 0.0;

      return (accuracy * 0.40) +
          (biasDetection * 0.20) +
          (reflection * 0.20) +
          (justification * 0.20);
    }

    // Memory: Simple weighted average (matches ResultsScreen calculation)
    double _calculateMemory(Map<String, double> memMetrics) {
      if (memMetrics.isEmpty) return 0.0;
      final sum = memMetrics.values.reduce((a, b) => a + b);
      return sum / memMetrics.length;
    }

    // Creativity: Weighted formula
    double _calculateCreativity(Map<String, double> crMetrics) {
      if (crMetrics.isEmpty) return 0.0;
      final fluency = crMetrics['Fluency'] ?? 0.0;
      final flexibility = crMetrics['Flexibility'] ?? 0.0;
      final originality = crMetrics['Originality'] ?? 0.0;
      final refinement = crMetrics['Refinement Gain'] ?? 0.0;

      return (fluency * 0.30) +
          (flexibility * 0.25) +
          (originality * 0.25) +
          (refinement * 0.20);
    }

    return {
      'criticalThinking': _calculateCriticalThinking(
        metrics['criticalThinking']!,
      ),
      'memory': _calculateMemory(metrics['memory']!),
      'creativity': _calculateCreativity(metrics['creativity']!),
    };
  }

  static Future<bool> hasCompletedAssessment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasCompletedAssessmentKey) ?? false;
  }

  static Future<void> clearScores() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ctMetricsKey);
    await prefs.remove(_memMetricsKey);
    await prefs.remove(_crMetricsKey);
    await prefs.remove(_hasCompletedAssessmentKey);
  }
}
