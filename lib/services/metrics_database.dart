import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite database for storing user metrics over time.
///
/// Schema:
/// - metric_sessions: Stores 12 metrics per session with timestamp
///
/// Supports:
/// - Insert metrics per session
/// - Query metrics over time for graphing
/// - Domain-level and individual metric trends
class MetricsDatabase {
  static Database? _database;
  static const String _dbName = 'rheto_metrics.db';
  static const int _dbVersion = 1;

  // Metric names by domain (canonical keys used in database)
  static const Map<String, List<String>> domainMetrics = {
    'critical_thinking': [
      'accuracy_rate',
      'bias_detection_rate',
      'cognitive_reflection',
      'justification_quality',
    ],
    'memory': [
      'recall_accuracy',
      'recall_latency',
      'retention_curve',
      'item_mastery',
    ],
    'creativity': ['fluency', 'flexibility', 'originality', 'refinement_gain'],
  };

  // Domain score weights (matching ScoreStorageService)
  static const Map<String, Map<String, double>> domainWeights = {
    'critical_thinking': {
      'accuracy_rate': 0.40,
      'bias_detection_rate': 0.20,
      'cognitive_reflection': 0.20,
      'justification_quality': 0.20,
    },
    'memory': {
      'recall_accuracy': 0.25,
      'recall_latency': 0.25,
      'retention_curve': 0.25,
      'item_mastery': 0.25,
    },
    'creativity': {
      'fluency': 0.30,
      'flexibility': 0.25,
      'originality': 0.25,
      'refinement_gain': 0.20,
    },
  };

  /// Get database instance (singleton)
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    // Single table for all metric sessions
    // Each row = one session with all 12 metrics + timestamp
    await db.execute('''
      CREATE TABLE metric_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp INTEGER NOT NULL,
        
        -- Critical Thinking metrics (0-10 scale)
        accuracy_rate REAL NOT NULL DEFAULT 0,
        bias_detection_rate REAL NOT NULL DEFAULT 0,
        cognitive_reflection REAL NOT NULL DEFAULT 0,
        justification_quality REAL NOT NULL DEFAULT 0,
        
        -- Memory metrics (0-10 scale)
        recall_accuracy REAL NOT NULL DEFAULT 0,
        recall_latency REAL NOT NULL DEFAULT 0,
        retention_curve REAL NOT NULL DEFAULT 0,
        item_mastery REAL NOT NULL DEFAULT 0,
        
        -- Creativity metrics (0-10 scale)
        fluency REAL NOT NULL DEFAULT 0,
        flexibility REAL NOT NULL DEFAULT 0,
        originality REAL NOT NULL DEFAULT 0,
        refinement_gain REAL NOT NULL DEFAULT 0
      )
    ''');

    // Index for time-based queries
    await db.execute('''
      CREATE INDEX idx_timestamp ON metric_sessions(timestamp)
    ''');
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Future migrations go here
  }

  /// Insert a new metric session with all 12 metrics
  ///
  /// [metrics] should contain all 12 metric values keyed by canonical names:
  /// - accuracy_rate, bias_detection_rate, cognitive_reflection, justification_quality
  /// - recall_accuracy, recall_latency, retention_curve, item_mastery
  /// - fluency, flexibility, originality, refinement_gain
  static Future<int> insertSession(Map<String, double> metrics) async {
    final db = await database;
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    return await db.insert('metric_sessions', {
      'timestamp': timestamp,
      'accuracy_rate': metrics['accuracy_rate'] ?? 0.0,
      'bias_detection_rate': metrics['bias_detection_rate'] ?? 0.0,
      'cognitive_reflection': metrics['cognitive_reflection'] ?? 0.0,
      'justification_quality': metrics['justification_quality'] ?? 0.0,
      'recall_accuracy': metrics['recall_accuracy'] ?? 0.0,
      'recall_latency': metrics['recall_latency'] ?? 0.0,
      'retention_curve': metrics['retention_curve'] ?? 0.0,
      'item_mastery': metrics['item_mastery'] ?? 0.0,
      'fluency': metrics['fluency'] ?? 0.0,
      'flexibility': metrics['flexibility'] ?? 0.0,
      'originality': metrics['originality'] ?? 0.0,
      'refinement_gain': metrics['refinement_gain'] ?? 0.0,
    });
  }

  /// Get all sessions within a time range
  ///
  /// [startTime] and [endTime] are DateTime objects
  /// Returns list of sessions with all metrics and timestamp
  static Future<List<MetricSession>> getSessions({
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    final db = await database;

    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startTime != null) {
      whereClause = 'timestamp >= ?';
      whereArgs.add(startTime.millisecondsSinceEpoch);
    }

    if (endTime != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'timestamp <= ?';
      whereArgs.add(endTime.millisecondsSinceEpoch);
    }

    final results = await db.query(
      'metric_sessions',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp ASC',
      limit: limit,
    );

    return results.map((row) => MetricSession.fromMap(row)).toList();
  }

  /// Get the latest session
  static Future<MetricSession?> getLatestSession() async {
    final db = await database;
    final results = await db.query(
      'metric_sessions',
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return MetricSession.fromMap(results.first);
  }

  /// Get sessions for the last N days
  static Future<List<MetricSession>> getSessionsForLastDays(int days) async {
    final endTime = DateTime.now();
    final startTime = endTime.subtract(Duration(days: days));
    return getSessions(startTime: startTime, endTime: endTime);
  }

  /// Get daily aggregated metrics (average per day)
  /// Returns a list of DailyMetrics with date and averaged values
  static Future<List<DailyMetrics>> getDailyAggregates({
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final sessions = await getSessions(startTime: startTime, endTime: endTime);

    // Group sessions by date
    final Map<String, List<MetricSession>> byDate = {};
    for (final session in sessions) {
      final dateKey = _dateKey(session.timestamp);
      byDate.putIfAbsent(dateKey, () => []).add(session);
    }

    // Calculate daily averages
    final List<DailyMetrics> dailyMetrics = [];
    for (final entry in byDate.entries) {
      final sessions = entry.value;
      final date = DateTime.parse(entry.key);

      dailyMetrics.add(
        DailyMetrics(date: date, metrics: _averageMetrics(sessions)),
      );
    }

    dailyMetrics.sort((a, b) => a.date.compareTo(b.date));
    return dailyMetrics;
  }

  static String _dateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  static Map<String, double> _averageMetrics(List<MetricSession> sessions) {
    if (sessions.isEmpty) return {};

    final allMetricNames = [
      ...domainMetrics['critical_thinking']!,
      ...domainMetrics['memory']!,
      ...domainMetrics['creativity']!,
    ];

    final Map<String, double> averages = {};
    for (final name in allMetricNames) {
      final sum = sessions.fold<double>(0, (acc, s) => acc + s.getMetric(name));
      averages[name] = sum / sessions.length;
    }
    return averages;
  }

  /// Calculate domain score from metrics using weights
  static double calculateDomainScore(
    String domain,
    Map<String, double> metrics,
  ) {
    final weights = domainWeights[domain];
    if (weights == null) return 0.0;

    double score = 0.0;
    for (final entry in weights.entries) {
      score += (metrics[entry.key] ?? 0.0) * entry.value;
    }
    return score;
  }

  /// Delete all sessions (for testing/reset)
  static Future<void> clearAllSessions() async {
    final db = await database;
    await db.delete('metric_sessions');
  }

  /// Get total session count
  static Future<int> getSessionCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM metric_sessions',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Close database connection
  static Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

/// Represents a single metric session with all 12 metrics
class MetricSession {
  final int id;
  final DateTime timestamp;

  // Critical Thinking
  final double accuracyRate;
  final double biasDetectionRate;
  final double cognitiveReflection;
  final double justificationQuality;

  // Memory
  final double recallAccuracy;
  final double recallLatency;
  final double retentionCurve;
  final double itemMastery;

  // Creativity
  final double fluency;
  final double flexibility;
  final double originality;
  final double refinementGain;

  MetricSession({
    required this.id,
    required this.timestamp,
    required this.accuracyRate,
    required this.biasDetectionRate,
    required this.cognitiveReflection,
    required this.justificationQuality,
    required this.recallAccuracy,
    required this.recallLatency,
    required this.retentionCurve,
    required this.itemMastery,
    required this.fluency,
    required this.flexibility,
    required this.originality,
    required this.refinementGain,
  });

  factory MetricSession.fromMap(Map<String, dynamic> map) {
    return MetricSession(
      id: map['id'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      accuracyRate: (map['accuracy_rate'] as num).toDouble(),
      biasDetectionRate: (map['bias_detection_rate'] as num).toDouble(),
      cognitiveReflection: (map['cognitive_reflection'] as num).toDouble(),
      justificationQuality: (map['justification_quality'] as num).toDouble(),
      recallAccuracy: (map['recall_accuracy'] as num).toDouble(),
      recallLatency: (map['recall_latency'] as num).toDouble(),
      retentionCurve: (map['retention_curve'] as num).toDouble(),
      itemMastery: (map['item_mastery'] as num).toDouble(),
      fluency: (map['fluency'] as num).toDouble(),
      flexibility: (map['flexibility'] as num).toDouble(),
      originality: (map['originality'] as num).toDouble(),
      refinementGain: (map['refinement_gain'] as num).toDouble(),
    );
  }

  Map<String, double> toMetricsMap() {
    return {
      'accuracy_rate': accuracyRate,
      'bias_detection_rate': biasDetectionRate,
      'cognitive_reflection': cognitiveReflection,
      'justification_quality': justificationQuality,
      'recall_accuracy': recallAccuracy,
      'recall_latency': recallLatency,
      'retention_curve': retentionCurve,
      'item_mastery': itemMastery,
      'fluency': fluency,
      'flexibility': flexibility,
      'originality': originality,
      'refinement_gain': refinementGain,
    };
  }

  double getMetric(String name) {
    switch (name) {
      case 'accuracy_rate':
        return accuracyRate;
      case 'bias_detection_rate':
        return biasDetectionRate;
      case 'cognitive_reflection':
        return cognitiveReflection;
      case 'justification_quality':
        return justificationQuality;
      case 'recall_accuracy':
        return recallAccuracy;
      case 'recall_latency':
        return recallLatency;
      case 'retention_curve':
        return retentionCurve;
      case 'item_mastery':
        return itemMastery;
      case 'fluency':
        return fluency;
      case 'flexibility':
        return flexibility;
      case 'originality':
        return originality;
      case 'refinement_gain':
        return refinementGain;
      default:
        return 0.0;
    }
  }

  /// Get Critical Thinking domain score (weighted)
  double get criticalThinkingScore {
    return MetricsDatabase.calculateDomainScore(
      'critical_thinking',
      toMetricsMap(),
    );
  }

  /// Get Memory domain score (weighted)
  double get memoryScore {
    return MetricsDatabase.calculateDomainScore('memory', toMetricsMap());
  }

  /// Get Creativity domain score (weighted)
  double get creativityScore {
    return MetricsDatabase.calculateDomainScore('creativity', toMetricsMap());
  }
}

/// Represents daily aggregated metrics
class DailyMetrics {
  final DateTime date;
  final Map<String, double> metrics;

  DailyMetrics({required this.date, required this.metrics});

  double getMetric(String name) => metrics[name] ?? 0.0;

  double get criticalThinkingScore {
    return MetricsDatabase.calculateDomainScore('critical_thinking', metrics);
  }

  double get memoryScore {
    return MetricsDatabase.calculateDomainScore('memory', metrics);
  }

  double get creativityScore {
    return MetricsDatabase.calculateDomainScore('creativity', metrics);
  }
}
