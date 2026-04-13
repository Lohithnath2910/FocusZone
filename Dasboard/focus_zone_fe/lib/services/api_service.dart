import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  // ---------------------------------------------------------------
  // ENDPOINT 1: /simulate-latest (GET)
  // Used by: DashboardController - polls every 20s for sensor data
  // Returns: temperature, humidity, light, noise, timestamp
  // ---------------------------------------------------------------
  Future<Map<String, dynamic>?> fetchLatestData(String baseUrl) async {
    try {
      final sanitizedBaseUrl = baseUrl.trim().replaceAll(RegExp(r'\/$'), '');
      final response = await http
          .get(Uri.parse('$sanitizedBaseUrl/simulate-latest'))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {}

    return null;
  }

  // ---------------------------------------------------------------
  // ENDPOINT 2: /sync (POST)
  // Used by: DashboardController - called every 20s alongside fetchLatestData
  // Sends: user_score (1-10) from latest session rating
  // Returns: predicted_score, vector, guidance, sensor_data
  // ---------------------------------------------------------------
  Future<Map<String, dynamic>?> sync(String baseUrl, int userScore) async {
    try {
      final sanitizedBaseUrl = baseUrl.trim().replaceAll(RegExp(r'\/$'), '');
      final response = await http
          .post(
            Uri.parse('$sanitizedBaseUrl/sync'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_score': userScore}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {}

    return null;
  }

  // ---------------------------------------------------------------
  // ENDPOINT 3: /feedback (POST)
  // Used by: SessionController - called when a session ends
  // Sends: feedback score (session star rating, 1-5)
  // Returns: confirmation message
  // ---------------------------------------------------------------
  Future<bool> sendFeedback(String baseUrl, int feedbackScore) async {
    try {
      final sanitizedBaseUrl = baseUrl.trim().replaceAll(RegExp(r'\/$'), '');
      final response = await http
          .post(
            Uri.parse('$sanitizedBaseUrl/feedback'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'feedback': feedbackScore}),
          )
          .timeout(const Duration(seconds: 6));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------
  // ENDPOINT 4: /insight (POST)
  // Used by: SessionController - called when a session ends
  // Sends: feedback score + session snapshot values
  // Returns: predicted_score, vector, labels, guidance
  // ---------------------------------------------------------------
  Future<Map<String, dynamic>?> fetchInsight({
    required String baseUrl,
    required int userScore,
    required Map<String, dynamic> snapshot,
  }) async {
    final temperature = _toDouble(snapshot['temperature']);
    final humidity = _toDouble(snapshot['humidity']);
    final light = _toDouble(snapshot['light']);

    if (temperature == null || humidity == null || light == null) {
      return null;
    }

    final payload = <String, dynamic>{
      'user_score': userScore,
      'temperature': temperature,
      'humidity': humidity,
      'light': light,
      'noise': _toDouble(snapshot['noise']) ?? 100.0,
    };

    try {
      final sanitizedBaseUrl = baseUrl.trim().replaceAll(RegExp(r'\/$'), '');
      final response = await http
          .post(
            Uri.parse('$sanitizedBaseUrl/insight'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      }
    } catch (_) {}

    return null;
  }

  double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    final text = value.toString();
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(text);
    if (match == null) {
      return null;
    }

    return double.tryParse(match.group(0)!);
  }
}
