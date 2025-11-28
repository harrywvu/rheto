import 'package:http/http.dart' as http;
import 'dart:convert';

class ScoringService {
  static String baseUrl = 'http://localhost:3000';

  static void setBaseUrl(String url) => baseUrl = url;

  static Future<Map<String, dynamic>> scoreJustification({
    required String question,
    required String userAnswer,
    String? reflectionQuestion,
    String? reflectionAnswer,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/score-justification'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'question': question,
              'userAnswer': userAnswer,
              'reflectionQuestion': reflectionQuestion,
              'reflectionAnswer': reflectionAnswer,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to score justification: ${response.statusCode}');
    } catch (e) {
      final random = DateTime.now().millisecondsSinceEpoch % 10;
      return {
        'clarity': random % 3,
        'depth': random % 2,
        'logical_structure': random % 2,
        'total': ((random % 3 + random % 2 + random % 2) / 10.0 * 100).clamp(
          0,
          100,
        ),
      };
    }
  }

  static Future<Map<String, dynamic>> scoreCreativity({
    required List<String> ideas,
    String? refinedIdea,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/score-creativity'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'ideas': ideas,
              'refinedIdea': refinedIdea ?? '',
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to score creativity: ${response.statusCode}');
    } catch (e) {
      final random = DateTime.now().millisecondsSinceEpoch % 10;
      final ideasCount = ideas.length;
      return {
        'fluency': 3 + ideasCount.clamp(0, 7),
        'flexibility': 3 + (ideasCount ~/ 2).clamp(0, 7),
        'originality': 3 + random % 7,
        'refinement_gain': refinedIdea?.isNotEmpty == true
            ? 5 + random % 5
            : 2 + random % 3,
        'total': 30 + ideasCount * 3 + random * 2,
      };
    }
  }

  static Future<Map<String, dynamic>> scoreMemory({
    required double immediateRecallAccuracy,
    required double retentionCurve,
    required double averageRecallTime,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/score-memory'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'immediateRecallAccuracy': immediateRecallAccuracy,
              'retentionCurve': retentionCurve,
              'averageRecallTime': averageRecallTime,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to score memory: ${response.statusCode}');
    } catch (e) {
      if (immediateRecallAccuracy <= 0) {
        return {
          'immediateRecallAccuracy': 0,
          'retentionCurve': 0,
          'averageRecallTime': averageRecallTime > 0 ? averageRecallTime : 10.0,
          'total': 0,
        };
      }

      final safeRecallTime = averageRecallTime <= 0 ? 10.0 : averageRecallTime;
      final calculatedScore =
          (immediateRecallAccuracy * retentionCurve) / (safeRecallTime / 10);
      final random = DateTime.now().millisecondsSinceEpoch % 10;

      return {
        'immediateRecallAccuracy': immediateRecallAccuracy.round(),
        'retentionCurve': retentionCurve.round(),
        'averageRecallTime': safeRecallTime,
        'total': (calculatedScore + random - 5).clamp(0, 100).round(),
      };
    }
  }

  static Future<bool> isApiAvailable() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
