import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';

class SessionRecord {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;
  final int rating;
  final Map<String, dynamic> snapshot;

  const SessionRecord({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
    required this.rating,
    required this.snapshot,
  });

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    final startedAt =
        DateTime.tryParse(json['startedAt']?.toString() ?? '') ??
        DateTime.now();
    final endedAt =
        DateTime.tryParse(json['endedAt']?.toString() ?? '') ?? startedAt;
    final durationSeconds =
        (json['durationSeconds'] as num?)?.toInt() ??
        endedAt.difference(startedAt).inSeconds;

    return SessionRecord(
      id: json['id']?.toString() ?? startedAt.microsecondsSinceEpoch.toString(),
      startedAt: startedAt,
      endedAt: endedAt,
      duration: Duration(seconds: durationSeconds),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      snapshot: json['snapshot'] is Map
          ? Map<String, dynamic>.from(json['snapshot'] as Map)
          : <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'durationSeconds': duration.inSeconds,
      'rating': rating,
      'snapshot': snapshot,
    };
  }

  String get durationLabel {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }

    return '${seconds}s';
  }
}

class SessionController extends ChangeNotifier {
  SessionController() {
    _restoreState();
  }

  final ApiService _api = ApiService();
  final List<SessionRecord> history = <SessionRecord>[];
  Timer? _ticker;
  DateTime? _startedAt;
  Map<String, dynamic> _snapshot = <String, dynamic>{};

  bool isActive = false;
  Duration elapsed = Duration.zero;
  final ValueNotifier<Duration> elapsedNotifier = ValueNotifier<Duration>(
    Duration.zero,
  );
  SessionRecord? lastCompletedSession;

  void _restoreState() {
    history
      ..clear()
      ..addAll(StorageService.getSessionHistory().map(SessionRecord.fromJson));

    final active = StorageService.getActiveSession();
    if (active != null) {
      _startedAt = DateTime.tryParse(active['startedAt']?.toString() ?? '');
      _snapshot = active['snapshot'] is Map
          ? Map<String, dynamic>.from(active['snapshot'] as Map)
          : <String, dynamic>{};
      isActive = _startedAt != null;
      if (isActive) {
        elapsed = DateTime.now().difference(_startedAt!);
        elapsedNotifier.value = elapsed;
        _startTicker();
      }
    }

    if (history.isNotEmpty) {
      lastCompletedSession = history.first;
    }

    notifyListeners();
  }

  Future<void> startSession({Map<String, dynamic>? snapshot}) async {
    if (isActive) {
      return;
    }

    _startedAt = DateTime.now();
    _snapshot = snapshot ?? <String, dynamic>{};
    isActive = true;
    elapsed = Duration.zero;
    elapsedNotifier.value = elapsed;
    lastCompletedSession = history.isNotEmpty
        ? history.first
        : lastCompletedSession;
    _startTicker();

    await StorageService.saveActiveSession({
      'startedAt': _startedAt!.toIso8601String(),
      'snapshot': _snapshot,
    });

    notifyListeners();
  }

  Future<SessionRecord?> stopSession({
    required int rating,
    Map<String, dynamic>? snapshot,
  }) async {
    if (!isActive || _startedAt == null) {
      return null;
    }

    final endedAt = DateTime.now();
    final mergedSnapshot = {
      ...Map<String, dynamic>.from(_snapshot),
      if (snapshot != null) ...Map<String, dynamic>.from(snapshot),
    };

    final baseUrl = mergedSnapshot['baseUrl']?.toString() ?? '';
    if (baseUrl.trim().isNotEmpty) {
      await _api.sendFeedback(baseUrl, rating.clamp(1, 10));

      final insight = await _api.fetchInsight(
        baseUrl: baseUrl,
        userScore: rating.clamp(1, 10),
        snapshot: mergedSnapshot,
      );

      final insightText = insight?['guidance']?.toString().trim();
      if (insightText != null && insightText.isNotEmpty) {
        mergedSnapshot['insight'] = insightText;
      }
      if (insight?['predicted_score'] != null) {
        mergedSnapshot['insightPredictedScore'] = insight?['predicted_score']
            .toString();
      }
    }

    final record = SessionRecord(
      id: endedAt.microsecondsSinceEpoch.toString(),
      startedAt: _startedAt!,
      endedAt: endedAt,
      duration: endedAt.difference(_startedAt!),
      rating: rating.clamp(1, 10),
      snapshot: mergedSnapshot,
    );

    history.insert(0, record);
    lastCompletedSession = record;
    elapsed = record.duration;
    elapsedNotifier.value = elapsed;
    isActive = false;
    _startedAt = null;
    _snapshot = <String, dynamic>{};
    _ticker?.cancel();
    _ticker = null;

    await StorageService.saveSessionHistory(
      history.map((item) => item.toJson()).toList(),
    );
    await StorageService.saveActiveSession(null);
    notifyListeners();
    return record;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startedAt == null) {
        return;
      }

      elapsed = DateTime.now().difference(_startedAt!);
      elapsedNotifier.value = elapsed;
    });
  }

  Future<void> resetAll() async {
    _ticker?.cancel();
    _ticker = null;
    _startedAt = null;
    _snapshot = <String, dynamic>{};
    isActive = false;
    elapsed = Duration.zero;
    elapsedNotifier.value = elapsed;
    history.clear();
    lastCompletedSession = null;
    await StorageService.clearSessions();
    notifyListeners();
  }

  Future<void> clearHistoryOnly() async {
    history.clear();
    lastCompletedSession = null;
    await StorageService.clearSessions();
    if (!isActive) {
      elapsed = Duration.zero;
      elapsedNotifier.value = elapsed;
    }
    notifyListeners();
  }

  Map<String, dynamic> get currentSnapshot =>
      Map<String, dynamic>.unmodifiable(_snapshot);

  String get statusLabel => isActive ? 'Session running' : 'Ready to start';

  String get durationLabel {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60);
    final seconds = elapsed.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    elapsedNotifier.dispose();
    super.dispose();
  }
}
