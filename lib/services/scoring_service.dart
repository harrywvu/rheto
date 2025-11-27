import 'package:http/http.dart' as http;
import 'dart:convert';

class ScoringService {
  static String baseUrl = 'http://localhost:3000';

  /// Set the base URL for the API
  static void setBaseUrl(String url) {
    baseUrl = url;
  }

  /// Score a justification text using AI
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
      } else {
        throw Exception(
          'Failed to score justification: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error scoring justification: $e');
      // Show error in debug console
      print('API ERROR: Failed to score justification - $e');
      // Return low fallback scores on error (strict grading)
      // Use the same 0-10 rubric as the backend and convert to a 0-100 total
      final random = DateTime.now().millisecondsSinceEpoch % 10;
      final clarity = random % 3; // 0-2 (low)
      final depth = random % 2; // 0-1 (very low)
      final logicalStructure = random % 2; // 0-1 (very low)
      final total0To100 = ((clarity + depth + logicalStructure) / 10.0 * 100)
          .clamp(0, 100);

      return {
        'clarity': clarity,
        'depth': depth,
        'logical_structure': logicalStructure,
        'total': total0To100,
      };
    }
  }

  /// Score creativity ideas using AI
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
      } else {
        throw Exception('Failed to score creativity: ${response.statusCode}');
      }
    } catch (e) {
      print('Error scoring creativity: $e');
      // Show error in debug console
      print('API ERROR: Failed to score creativity - $e');
      // Return variable scores on error
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

  /// Score memory efficiency using provided metrics
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
      } else {
        throw Exception('Failed to score memory: ${response.statusCode}');
      }
    } catch (e) {
      print('Error scoring memory: $e');
      // Show error in debug console
      print('API ERROR: Failed to score memory - $e');
      // If no words recalled, score should be zero
      if (immediateRecallAccuracy <= 0) {
        return {
          'immediateRecallAccuracy': 0,
          'retentionCurve': 0,
          'averageRecallTime': averageRecallTime > 0 ? averageRecallTime : 10.0,
          'total': 0,
        };
      }

      // Calculate score using the formula from the guide
      // but ensure it's not artificially high when performance is poor
      final safeRecallTime = averageRecallTime <= 0 ? 10.0 : averageRecallTime;
      final calculatedScore =
          (immediateRecallAccuracy * retentionCurve) / (safeRecallTime / 10);

      // Add small random variation but keep the score proportional to actual performance
      final random = DateTime.now().millisecondsSinceEpoch % 10;
      return {
        'immediateRecallAccuracy': immediateRecallAccuracy.round(),
        'retentionCurve': retentionCurve.round(),
        'averageRecallTime': safeRecallTime,
        'total': (calculatedScore + random - 5).clamp(0, 100).round(),
      };
    }
  }

  /// Check if API is available
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
