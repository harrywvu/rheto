import 'dart:convert';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Background service for daily metric snapshots at midnight
class BackgroundMetricService {
  static const String _lastBackgroundUploadKey =
      'last_background_metric_upload';

  /// Initialize background service for daily midnight uploads
  static Future<void> initializeBackgroundService() async {
    final service = FlutterBackgroundService();

    // Define what the background task does
    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        isForegroundMode: false,
        autoStart: true,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    // Start the service
    service.startService();
  }

  /// Background task that runs periodically
  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    // Check every hour if it's time to upload (midnight)
    service.on('update').listen((event) async {
      await _checkAndUploadMetrics();
    });

    // Also check periodically
    Future.delayed(Duration.zero, () async {
      while (true) {
        await Future.delayed(const Duration(hours: 1));
        await _checkAndUploadMetrics();
      }
    });
  }

  /// iOS background handler
  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    await _checkAndUploadMetrics();
    return true;
  }

  /// Check if it's midnight and upload metrics
  static Future<void> _checkAndUploadMetrics() async {
    try {
      final now = DateTime.now();
      final prefs = await SharedPreferences.getInstance();

      // Check if we already uploaded today
      final lastUpload = prefs.getString(_lastBackgroundUploadKey);
      if (lastUpload != null) {
        final lastUploadDate = DateTime.parse(lastUpload);
        if (lastUploadDate.year == now.year &&
            lastUploadDate.month == now.month &&
            lastUploadDate.day == now.day) {
          // Already uploaded today
          return;
        }
      }

      // Check if it's close to midnight (between 11:55 PM and 12:05 AM)
      final hour = now.hour;
      final minute = now.minute;

      final isMidnightWindow =
          (hour == 23 && minute >= 55) || (hour == 0 && minute <= 5);

      if (!isMidnightWindow) {
        // Not midnight yet
        return;
      }

      // It's midnight! Upload metrics
      await _uploadMetricsNow(prefs);
    } catch (e) {
      print('Error in background metric check: $e');
    }
  }

  /// Upload metrics to Supabase
  static Future<void> _uploadMetricsNow(SharedPreferences prefs) async {
    try {
      // Get metrics from local storage
      final ctMetricsJson = prefs.getString('critical_thinking_metrics');
      final memMetricsJson = prefs.getString('memory_metrics');
      final crMetricsJson = prefs.getString('creativity_metrics');

      if (ctMetricsJson == null ||
          memMetricsJson == null ||
          crMetricsJson == null) {
        print('No metrics to upload');
        return;
      }

      // Parse metrics
      final Map<String, double> ctMetrics = _parseMetrics(ctMetricsJson);
      final Map<String, double> memMetrics = _parseMetrics(memMetricsJson);
      final Map<String, double> crMetrics = _parseMetrics(crMetricsJson);

      // Prepare snapshots
      final snapshots = <Map<String, dynamic>>[];
      final now = DateTime.now();

      // Critical Thinking
      ctMetrics.forEach((name, value) {
        snapshots.add({
          'user_id': 'placeholder-user-id', // TODO: Replace with auth user ID
          'domain': 'critical_thinking',
          'metric_name': name,
          'value': value,
          'captured_at': now.toIso8601String(),
        });
      });

      // Memory
      memMetrics.forEach((name, value) {
        snapshots.add({
          'user_id': 'placeholder-user-id',
          'domain': 'memory',
          'metric_name': name,
          'value': value,
          'captured_at': now.toIso8601String(),
        });
      });

      // Creativity
      crMetrics.forEach((name, value) {
        snapshots.add({
          'user_id': 'placeholder-user-id',
          'domain': 'creativity',
          'metric_name': name,
          'value': value,
          'captured_at': now.toIso8601String(),
        });
      });

      // Upload to Supabase
      final supabase = Supabase.instance.client;
      await supabase.from('metric_snapshots').insert(snapshots);

      // Mark as uploaded
      await prefs.setString(_lastBackgroundUploadKey, now.toIso8601String());

      print(
        'Background: Successfully uploaded ${snapshots.length} metric snapshots at midnight',
      );
    } catch (e) {
      print('Error uploading metrics in background: $e');
    }
  }

  /// Parse metrics from JSON string
  static Map<String, double> _parseMetrics(String json) {
    try {
      final decoded = (jsonDecode(json) as Map).cast<String, dynamic>();
      return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (e) {
      print('Error parsing metrics: $e');
      return {};
    }
  }
}
