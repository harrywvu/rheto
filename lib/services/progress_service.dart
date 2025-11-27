import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:rheto/models/module.dart';
import 'package:rheto/services/score_storage_service.dart';

class ProgressService {
  static const String _progressKey = 'user_progress';
  static const String _lastStreakCheckKey = 'last_streak_check_date';

  /// Get user's current progress
  static Future<UserProgress> getProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_progressKey);

    if (progressJson == null) {
      // Return default progress for new user
      return UserProgress(
        totalCoins: 0,
        currentStreak: 0,
        lastActivityDate: DateTime.now().subtract(Duration(days: 1)),
        completedActivities: [],
        modulesCompletedToday: {
          'criticalThinking': 0,
          'memory': 0,
          'creativity': 0,
        },
        baselineMetrics: {
          'criticalThinking': {},
          'memory': {},
          'creativity': {},
        },
      );
    }

    return UserProgress.fromJson(jsonDecode(progressJson));
  }

  /// Save user progress
  static Future<void> saveProgress(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }

  /// Record activity completion and update progress
  static Future<UserProgress> completeActivity({
    required String activityId,
    required double score,
    required String moduleType,
    required Map<String, dynamic> metrics,
  }) async {
    final progress = await getProgress();

    // Calculate currency earned based on score
    final baseReward = 50;
    final currencyEarned = (baseReward * (score / 100)).round();

    // Create activity result
    final result = ActivityResult(
      activityId: activityId,
      completedAt: DateTime.now(),
      score: score,
      currencyEarned: currencyEarned,
      metrics: metrics,
    );

    // Update progress
    var updatedProgress = UserProgress(
      totalCoins: progress.totalCoins + currencyEarned,
      currentStreak: progress.currentStreak,
      lastActivityDate: progress.lastActivityDate,
      completedActivities: [...progress.completedActivities, result],
      modulesCompletedToday: {
        ...progress.modulesCompletedToday,
        moduleType: (progress.modulesCompletedToday[moduleType] ?? 0) + 1,
      },
      baselineMetrics: progress.baselineMetrics,
    );

    // Check if streak should increase
    if (updatedProgress.canIncreaseStreak()) {
      final today = DateTime.now();
      final lastCheck = await _getLastStreakCheckDate();

      // Only increase streak once per day
      if (lastCheck == null || !_isSameDay(lastCheck, today)) {
        updatedProgress = UserProgress(
          totalCoins: updatedProgress.totalCoins,
          currentStreak: updatedProgress.currentStreak + 1,
          lastActivityDate: today,
          completedActivities: updatedProgress.completedActivities,
          modulesCompletedToday: updatedProgress.modulesCompletedToday,
          baselineMetrics: updatedProgress.baselineMetrics,
        );

        await _setLastStreakCheckDate(today);
      }
    }

    await saveProgress(updatedProgress);

    // Update baseline metrics with activity metrics
    await _updateBaselineMetricsFromActivity(
      moduleType: moduleType,
      activityMetrics: metrics,
    );

    return updatedProgress;
  }

  /// Update baseline metrics by merging activity metrics
  static Future<void> _updateBaselineMetricsFromActivity({
    required String moduleType,
    required Map<String, dynamic> activityMetrics,
  }) async {
    print('📊 _updateBaselineMetricsFromActivity called for $moduleType');
    print('   Activity metrics: $activityMetrics');

    final currentMetrics = await ScoreStorageService.getMetrics();
    print('   Current baseline metrics: $currentMetrics');

    // Get the module's metrics
    final moduleMetrics = currentMetrics[moduleType] ?? {};

    // Add activity points to baseline metrics (point-based system)
    // Critical Thinking: Accuracy +3, Bias Detection +2, Cognitive Reflection +1, Justification +4
    // Memory: Recall Accuracy +3, Recall Latency +2, Retention Curve +3, Item Mastery +1
    if (activityMetrics.containsKey('accuracyRate')) {
      final points = (activityMetrics['accuracyRate'] as num).toInt();
      moduleMetrics['Accuracy'] = (moduleMetrics['Accuracy'] ?? 0.0) + points;
      print('   Accuracy: +$points points');
    }
    if (activityMetrics.containsKey('biasDetectionRate')) {
      final points = (activityMetrics['biasDetectionRate'] as num).toInt();
      moduleMetrics['Bias Detection'] =
          (moduleMetrics['Bias Detection'] ?? 0.0) + points;
      print('   Bias Detection: +$points points');
    }
    if (activityMetrics.containsKey('cognitiveReflection')) {
      final points = (activityMetrics['cognitiveReflection'] as num).toInt();
      moduleMetrics['Cognitive Reflection'] =
          (moduleMetrics['Cognitive Reflection'] ?? 0.0) + points;
      print('   Cognitive Reflection: +$points points');
    }
    if (activityMetrics.containsKey('justificationQuality')) {
      final points = (activityMetrics['justificationQuality'] as num).toInt();
      moduleMetrics['Justification Quality'] =
          (moduleMetrics['Justification Quality'] ?? 0.0) + points;
      print('   Justification Quality: +$points points');
    }
    if (activityMetrics.containsKey('recallAccuracy')) {
      final points = (activityMetrics['recallAccuracy'] as num).toInt();
      moduleMetrics['Recall Accuracy'] =
          (moduleMetrics['Recall Accuracy'] ?? 0.0) + points;
      print('   Recall Accuracy: +$points points');
    }
    if (activityMetrics.containsKey('recallLatency')) {
      final points = (activityMetrics['recallLatency'] as num).toInt();
      moduleMetrics['Recall Latency'] =
          (moduleMetrics['Recall Latency'] ?? 0.0) + points;
      print('   Recall Latency: +$points points');
    }
    if (activityMetrics.containsKey('retentionCurve')) {
      final points = (activityMetrics['retentionCurve'] as num).toInt();
      moduleMetrics['Retention Curve'] =
          (moduleMetrics['Retention Curve'] ?? 0.0) + points;
      print('   Retention Curve: +$points points');
    }
    if (activityMetrics.containsKey('itemMastery')) {
      final points = (activityMetrics['itemMastery'] as num).toInt();
      moduleMetrics['Item Mastery'] =
          (moduleMetrics['Item Mastery'] ?? 0.0) + points;
      print('   Item Mastery: +$points points');
    }

    // Update the metrics map
    currentMetrics[moduleType] = moduleMetrics;

    // Save updated metrics back to ScoreStorageService
    print('   Saving updated metrics: $currentMetrics');
    await ScoreStorageService.saveMetrics(
      criticalThinkingMetrics: currentMetrics['criticalThinking'] ?? {},
      memoryMetrics: currentMetrics['memory'] ?? {},
      creativityMetrics: currentMetrics['creativity'] ?? {},
    );

    // Verify the save
    final verifyMetrics = await ScoreStorageService.getMetrics();
    print('✅ Updated baseline metrics for $moduleType');
    print('   Updated metrics: $moduleMetrics');
    print('   Verified saved metrics: $verifyMetrics');
  }

  /// Update baseline metrics from initial assessment
  static Future<void> updateBaselineMetrics({
    required Map<String, double> criticalThinkingMetrics,
    required Map<String, double> memoryMetrics,
    required Map<String, double> creativityMetrics,
  }) async {
    final progress = await getProgress();

    final updatedProgress = UserProgress(
      totalCoins: progress.totalCoins,
      currentStreak: progress.currentStreak,
      lastActivityDate: progress.lastActivityDate,
      completedActivities: progress.completedActivities,
      modulesCompletedToday: progress.modulesCompletedToday,
      baselineMetrics: {
        'criticalThinking': criticalThinkingMetrics,
        'memory': memoryMetrics,
        'creativity': creativityMetrics,
      },
    );

    await saveProgress(updatedProgress);
  }

  /// Reset daily activity counts (call at midnight or app startup)
  static Future<void> resetDailyActivities() async {
    final progress = await getProgress();
    final today = DateTime.now();
    final lastActivity = progress.lastActivityDate;

    // Only reset if it's a new day
    if (!_isSameDay(lastActivity, today)) {
      final resetProgress = UserProgress(
        totalCoins: progress.totalCoins,
        currentStreak: progress.currentStreak,
        lastActivityDate: today,
        completedActivities: progress.completedActivities,
        modulesCompletedToday: {
          'criticalThinking': 0,
          'memory': 0,
          'creativity': 0,
        },
        baselineMetrics: progress.baselineMetrics,
      );

      await saveProgress(resetProgress);
    }
  }

  /// Get last streak check date
  static Future<DateTime?> _getLastStreakCheckDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_lastStreakCheckKey);
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  /// Set last streak check date
  static Future<void> _setLastStreakCheckDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastStreakCheckKey, date.toIso8601String());
  }

  /// Check if two dates are the same day
  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Clear all progress (for testing)
  static Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
    await prefs.remove(_lastStreakCheckKey);
  }
}
