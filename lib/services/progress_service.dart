import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:rheto/models/module.dart';
import 'package:rheto/services/score_storage_service.dart';
import 'package:rheto/services/notification_service.dart';

class ProgressService {
  static const String _progressKey = 'user_progress';
  static const String _lastStreakCheckKey = 'last_streak_check_date';

  static Future<UserProgress> getProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString(_progressKey);

    if (progressJson == null) {
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

  static Future<void> saveProgress(UserProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
  }

  static Future<UserProgress> completeActivity({
    required String activityId,
    required double score,
    required String moduleType,
    required Map<String, dynamic> metrics,
  }) async {
    final progress = await getProgress();
    final currencyEarned = (50 * (score / 100)).round();

    final result = ActivityResult(
      activityId: activityId,
      completedAt: DateTime.now(),
      score: score,
      currencyEarned: currencyEarned,
      metrics: metrics,
    );

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

    if (updatedProgress.canIncreaseStreak()) {
      final today = DateTime.now();
      final lastCheck = await _getLastStreakCheckDate();

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
    await _updateBaselineMetricsFromActivity(
      moduleType: moduleType,
      activityMetrics: metrics,
    );

    await NotificationService().showContextualNotification();

    return updatedProgress;
  }

  static Future<void> _updateBaselineMetricsFromActivity({
    required String moduleType,
    required Map<String, dynamic> activityMetrics,
  }) async {
    final currentMetrics = await ScoreStorageService.getMetrics();
    final moduleMetrics = currentMetrics[moduleType] ?? {};

    const metricMap = {
      'accuracyRate': 'Accuracy',
      'biasDetectionRate': 'Bias Detection',
      'cognitiveReflection': 'Cognitive Reflection',
      'justificationQuality': 'Justification Quality',
      'recallAccuracy': 'Recall Accuracy',
      'recallLatency': 'Recall Latency',
      'retentionCurve': 'Retention Curve',
      'itemMastery': 'Item Mastery',
      'fluency': 'Fluency',
      'flexibility': 'Flexibility',
      'originality': 'Originality',
      'refinement_gain': 'Refinement Gain',
    };

    metricMap.forEach((key, displayName) {
      if (activityMetrics.containsKey(key)) {
        final points = (activityMetrics[key] as num).toInt();
        moduleMetrics[displayName] =
            (moduleMetrics[displayName] ?? 0.0) + points;
      }
    });

    currentMetrics[moduleType] = moduleMetrics;
    await ScoreStorageService.saveMetrics(
      criticalThinkingMetrics: currentMetrics['criticalThinking'] ?? {},
      memoryMetrics: currentMetrics['memory'] ?? {},
      creativityMetrics: currentMetrics['creativity'] ?? {},
    );
  }

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

  static Future<void> resetDailyActivities() async {
    final progress = await getProgress();
    final today = DateTime.now();

    if (!_isSameDay(progress.lastActivityDate, today)) {
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

  static Future<DateTime?> _getLastStreakCheckDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_lastStreakCheckKey);
    return dateStr != null ? DateTime.parse(dateStr) : null;
  }

  static Future<void> _setLastStreakCheckDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastStreakCheckKey, date.toIso8601String());
  }

  static bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  static Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
    await prefs.remove(_lastStreakCheckKey);
  }
}
