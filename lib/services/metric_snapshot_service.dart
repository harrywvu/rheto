import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MetricSnapshotService {
  static const String _lastSnapshotDateKey = 'last_metric_snapshot_date';

  /// Check if a snapshot has already been uploaded today
  static Future<bool> hasUploadedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastSnapshotDateKey);

    if (lastDate == null) return false;

    final today = DateTime.now();
    final lastSnapshotDate = DateTime.parse(lastDate);

    // Check if last snapshot was on a different day
    return lastSnapshotDate.year == today.year &&
        lastSnapshotDate.month == today.month &&
        lastSnapshotDate.day == today.day;
  }

  /// Upload daily metric snapshots to Supabase
  /// Returns true if successful, false otherwise
  static Future<bool> uploadDailySnapshots({
    required String userId,
    required Map<String, double> criticalThinkingMetrics,
    required Map<String, double> memoryMetrics,
    required Map<String, double> creativityMetrics,
  }) async {
    try {
      // Check if already uploaded today
      if (await hasUploadedToday()) {
        print('Metrics already uploaded today');
        return true;
      }

      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      // Prepare all snapshot records
      final snapshots = <Map<String, dynamic>>[];

      // Critical Thinking metrics
      criticalThinkingMetrics.forEach((metricName, value) {
        snapshots.add({
          'user_id': userId,
          'domain': 'critical_thinking',
          'metric_name': metricName,
          'value': value,
          'captured_at': now.toIso8601String(),
        });
      });

      // Memory metrics
      memoryMetrics.forEach((metricName, value) {
        snapshots.add({
          'user_id': userId,
          'domain': 'memory',
          'metric_name': metricName,
          'value': value,
          'captured_at': now.toIso8601String(),
        });
      });

      // Creativity metrics
      creativityMetrics.forEach((metricName, value) {
        snapshots.add({
          'user_id': userId,
          'domain': 'creativity',
          'metric_name': metricName,
          'value': value,
          'captured_at': now.toIso8601String(),
        });
      });

      // Insert all snapshots in batch
      await supabase.from('metric_snapshots').insert(snapshots);

      // Update last snapshot date
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSnapshotDateKey, now.toIso8601String());

      print('Successfully uploaded ${snapshots.length} metric snapshots');
      return true;
    } catch (e) {
      print('Error uploading metric snapshots: $e');
      return false;
    }
  }

  /// Get all snapshots for a user within a date range
  static Future<List<Map<String, dynamic>>> getSnapshotsForUser({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      var query = supabase
          .from('metric_snapshots')
          .select()
          .eq('user_id', userId);

      if (startDate != null) {
        query = query.gte('captured_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('captured_at', endDate.toIso8601String());
      }

      final response = await query.order('captured_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error fetching metric snapshots: $e');
      return [];
    }
  }

  /// Get snapshots for a specific domain
  static Future<List<Map<String, dynamic>>> getSnapshotsForDomain({
    required String userId,
    required String domain,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final supabase = Supabase.instance.client;

      var query = supabase
          .from('metric_snapshots')
          .select()
          .eq('user_id', userId)
          .eq('domain', domain);

      if (startDate != null) {
        query = query.gte('captured_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('captured_at', endDate.toIso8601String());
      }

      final response = await query.order('captured_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      print('Error fetching domain snapshots: $e');
      return [];
    }
  }

  /// Clear the last snapshot date (for testing purposes)
  static Future<void> clearLastSnapshotDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastSnapshotDateKey);
  }
}
