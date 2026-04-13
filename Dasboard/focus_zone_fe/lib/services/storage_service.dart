import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _latestDataKey = 'focus_zone_latest_data';
  static const String _sessionHistoryKey = 'focus_zone_session_history';
  static const String _activeSessionKey = 'focus_zone_active_session';
  static const String _themeValueKey = 'focus_zone_theme_value';
  static const String _baseUrlKey = 'focus_zone_base_url';
  static const String _savedBaseUrlsKey = 'focus_zone_saved_base_urls';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get _storage {
    final storage = _prefs;
    if (storage == null) {
      throw StateError('StorageService must be initialized before use.');
    }
    return storage;
  }

  static Future<void> saveLatestData(Map<String, dynamic> data) async {
    await _storage.setString(_latestDataKey, jsonEncode(data));
  }

  static Map<String, dynamic>? getLatestData() {
    final raw = _storage.getString(_latestDataKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  static Future<void> saveSessionHistory(
    List<Map<String, dynamic>> history,
  ) async {
    await _storage.setString(_sessionHistoryKey, jsonEncode(history));
  }

  static List<Map<String, dynamic>> getSessionHistory() {
    final raw = _storage.getString(_sessionHistoryKey);
    if (raw == null || raw.isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  static Future<void> saveActiveSession(Map<String, dynamic>? session) async {
    if (session == null) {
      await _storage.remove(_activeSessionKey);
      return;
    }

    await _storage.setString(_activeSessionKey, jsonEncode(session));
  }

  static Map<String, dynamic>? getActiveSession() {
    final raw = _storage.getString(_activeSessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return null;
  }

  static Future<void> saveThemeValue(double value) async {
    await _storage.setDouble(_themeValueKey, value.clamp(0.0, 1.0));
  }

  static double getThemeValue({double fallback = 0.92}) {
    return _storage.getDouble(_themeValueKey) ?? fallback;
  }

  static Future<void> saveBaseUrl(String baseUrl) async {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      await _storage.remove(_baseUrlKey);
      return;
    }

    await _storage.setString(_baseUrlKey, trimmed);

    final saved = getSavedBaseUrls();
    final deduped = <String>[trimmed, ...saved.where((url) => url != trimmed)]
        .take(8)
        .toList();
    await _storage.setStringList(_savedBaseUrlsKey, deduped);
  }

  static String getBaseUrl() {
    return _storage.getString(_baseUrlKey) ?? '';
  }

  static List<String> getSavedBaseUrls() {
    return List<String>.from(_storage.getStringList(_savedBaseUrlsKey) ?? const <String>[]);
  }

  static Future<void> clearBaseUrl() async {
    await _storage.remove(_baseUrlKey);
  }

  static Future<void> clearSavedBaseUrls() async {
    await _storage.remove(_savedBaseUrlsKey);
  }

  static Future<void> clearLatestData() async {
    await _storage.remove(_latestDataKey);
  }

  static Future<void> clearSessions() async {
    await _storage.remove(_sessionHistoryKey);
    await _storage.remove(_activeSessionKey);
  }

  static Future<void> clearAll() async {
    await _storage.remove(_latestDataKey);
    await _storage.remove(_sessionHistoryKey);
    await _storage.remove(_activeSessionKey);
    await _storage.remove(_baseUrlKey);
    await _storage.remove(_savedBaseUrlsKey);
  }
}
