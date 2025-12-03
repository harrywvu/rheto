import 'package:fl_chart/fl_chart.dart';
import 'metrics_database.dart';

/// Service for querying metrics history and preparing data for charts.
///
/// Provides:
/// - Domain score trends over time
/// - Individual metric trends within a domain
/// - Chart-ready data structures for fl_chart
class MetricsHistoryService {
  /// Get domain score trend data for line charts
  ///
  /// Returns a list of FlSpot for each domain, suitable for fl_chart LineChart
  /// [days] - Number of days to include (default: 30)
  static Future<Map<String, List<FlSpot>>> getDomainTrends({
    int days = 30,
  }) async {
    final dailyMetrics = await MetricsDatabase.getDailyAggregates(
      startTime: DateTime.now().subtract(Duration(days: days)),
      endTime: DateTime.now(),
    );

    if (dailyMetrics.isEmpty) {
      return {'critical_thinking': [], 'memory': [], 'creativity': []};
    }

    final baseDate = dailyMetrics.first.date;

    return {
      'critical_thinking': dailyMetrics.map((dm) {
        final dayIndex = dm.date.difference(baseDate).inDays.toDouble();
        return FlSpot(dayIndex, dm.criticalThinkingScore);
      }).toList(),
      'memory': dailyMetrics.map((dm) {
        final dayIndex = dm.date.difference(baseDate).inDays.toDouble();
        return FlSpot(dayIndex, dm.memoryScore);
      }).toList(),
      'creativity': dailyMetrics.map((dm) {
        final dayIndex = dm.date.difference(baseDate).inDays.toDouble();
        return FlSpot(dayIndex, dm.creativityScore);
      }).toList(),
    };
  }

  /// Get individual metric trends for a specific domain
  ///
  /// [domain] - One of: 'critical_thinking', 'memory', 'creativity'
  /// [days] - Number of days to include (default: 30)
  ///
  /// Returns a map of metric name -> list of FlSpot
  static Future<Map<String, List<FlSpot>>> getMetricTrends({
    required String domain,
    int days = 30,
  }) async {
    final metricNames = MetricsDatabase.domainMetrics[domain];
    if (metricNames == null) return {};

    final dailyMetrics = await MetricsDatabase.getDailyAggregates(
      startTime: DateTime.now().subtract(Duration(days: days)),
      endTime: DateTime.now(),
    );

    if (dailyMetrics.isEmpty) {
      return {for (final name in metricNames) name: <FlSpot>[]};
    }

    final baseDate = dailyMetrics.first.date;
    final Map<String, List<FlSpot>> result = {};

    for (final metricName in metricNames) {
      result[metricName] = dailyMetrics.map((dm) {
        final dayIndex = dm.date.difference(baseDate).inDays.toDouble();
        return FlSpot(dayIndex, dm.getMetric(metricName));
      }).toList();
    }

    return result;
  }

  /// Get chart data with date labels for X-axis
  ///
  /// Returns both the FlSpot data and corresponding date labels
  static Future<ChartDataWithLabels> getDomainTrendsWithLabels({
    int days = 30,
  }) async {
    final dailyMetrics = await MetricsDatabase.getDailyAggregates(
      startTime: DateTime.now().subtract(Duration(days: days)),
      endTime: DateTime.now(),
    );

    if (dailyMetrics.isEmpty) {
      return ChartDataWithLabels(
        domainData: {'critical_thinking': [], 'memory': [], 'creativity': []},
        dateLabels: [],
      );
    }

    final baseDate = dailyMetrics.first.date;
    final dateLabels = dailyMetrics.map((dm) => dm.date).toList();

    return ChartDataWithLabels(
      domainData: {
        'critical_thinking': dailyMetrics.map((dm) {
          final dayIndex = dm.date.difference(baseDate).inDays.toDouble();
          return FlSpot(dayIndex, dm.criticalThinkingScore);
        }).toList(),
        'memory': dailyMetrics.map((dm) {
          final dayIndex = dm.date.difference(baseDate).inDays.toDouble();
          return FlSpot(dayIndex, dm.memoryScore);
        }).toList(),
        'creativity': dailyMetrics.map((dm) {
          final dayIndex = dm.date.difference(baseDate).inDays.toDouble();
          return FlSpot(dayIndex, dm.creativityScore);
        }).toList(),
      },
      dateLabels: dateLabels,
    );
  }

  /// Get latest metrics snapshot (most recent session)
  static Future<Map<String, double>?> getLatestMetrics() async {
    final session = await MetricsDatabase.getLatestSession();
    return session?.toMetricsMap();
  }

  /// Get latest domain scores
  static Future<Map<String, double>> getLatestDomainScores() async {
    final session = await MetricsDatabase.getLatestSession();
    if (session == null) {
      return {'critical_thinking': 0.0, 'memory': 0.0, 'creativity': 0.0};
    }
    return {
      'critical_thinking': session.criticalThinkingScore,
      'memory': session.memoryScore,
      'creativity': session.creativityScore,
    };
  }

  /// Get metric statistics over a time period
  ///
  /// Returns min, max, average, and latest value for each metric
  static Future<Map<String, MetricStats>> getMetricStats({
    int days = 30,
  }) async {
    final sessions = await MetricsDatabase.getSessionsForLastDays(days);
    if (sessions.isEmpty) return {};

    final allMetricNames = [
      ...MetricsDatabase.domainMetrics['critical_thinking']!,
      ...MetricsDatabase.domainMetrics['memory']!,
      ...MetricsDatabase.domainMetrics['creativity']!,
    ];

    final Map<String, MetricStats> stats = {};

    for (final name in allMetricNames) {
      final values = sessions.map((s) => s.getMetric(name)).toList();
      stats[name] = MetricStats(
        min: values.reduce((a, b) => a < b ? a : b),
        max: values.reduce((a, b) => a > b ? a : b),
        average: values.reduce((a, b) => a + b) / values.length,
        latest: values.last,
        count: values.length,
      );
    }

    return stats;
  }

  /// Get domain score statistics
  static Future<Map<String, MetricStats>> getDomainStats({
    int days = 30,
  }) async {
    final sessions = await MetricsDatabase.getSessionsForLastDays(days);
    if (sessions.isEmpty) {
      return {
        'critical_thinking': MetricStats.empty(),
        'memory': MetricStats.empty(),
        'creativity': MetricStats.empty(),
      };
    }

    final ctScores = sessions.map((s) => s.criticalThinkingScore).toList();
    final memScores = sessions.map((s) => s.memoryScore).toList();
    final crScores = sessions.map((s) => s.creativityScore).toList();

    return {
      'critical_thinking': MetricStats.fromValues(ctScores),
      'memory': MetricStats.fromValues(memScores),
      'creativity': MetricStats.fromValues(crScores),
    };
  }

  /// Check if there's enough data for meaningful charts
  static Future<bool> hasEnoughDataForCharts({int minSessions = 2}) async {
    final count = await MetricsDatabase.getSessionCount();
    return count >= minSessions;
  }

  /// Get session count
  static Future<int> getSessionCount() async {
    return await MetricsDatabase.getSessionCount();
  }
}

/// Chart data with date labels for X-axis formatting
class ChartDataWithLabels {
  final Map<String, List<FlSpot>> domainData;
  final List<DateTime> dateLabels;

  ChartDataWithLabels({required this.domainData, required this.dateLabels});

  /// Get formatted date label for a given X value
  String getDateLabel(double x) {
    final index = x.round();
    if (index < 0 || index >= dateLabels.length) return '';
    final date = dateLabels[index];
    return '${date.month}/${date.day}';
  }
}

/// Statistics for a single metric
class MetricStats {
  final double min;
  final double max;
  final double average;
  final double latest;
  final int count;

  MetricStats({
    required this.min,
    required this.max,
    required this.average,
    required this.latest,
    required this.count,
  });

  factory MetricStats.empty() {
    return MetricStats(min: 0, max: 0, average: 0, latest: 0, count: 0);
  }

  factory MetricStats.fromValues(List<double> values) {
    if (values.isEmpty) return MetricStats.empty();
    return MetricStats(
      min: values.reduce((a, b) => a < b ? a : b),
      max: values.reduce((a, b) => a > b ? a : b),
      average: values.reduce((a, b) => a + b) / values.length,
      latest: values.last,
      count: values.length,
    );
  }

  /// Calculate improvement from first to latest
  double get improvement => latest - min;

  /// Calculate percentage improvement
  double get improvementPercent {
    if (min == 0) return 0;
    return ((latest - min) / min) * 100;
  }
}
