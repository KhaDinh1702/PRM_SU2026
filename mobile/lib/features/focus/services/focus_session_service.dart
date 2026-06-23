import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth_service.dart';
import '../models/focus_session.dart';

/// Local-first store for focus sessions. Persists via SharedPreferences
/// under a single JSON list keyed by user id so multiple accounts on the
/// same device don't bleed history. Each save attempts a best-effort
/// remote sync — failures don't roll back the local write, so the user
/// never loses progress when offline.
class FocusSessionService {
  static const String _prefsPrefix = 'focus_sessions_v1::';
  static const int _maxStoredSessions = 500;

  const FocusSessionService();

  String _key(String userId) =>
      '$_prefsPrefix${userId.isEmpty ? 'anon' : userId}';

  /// Loads every persisted session for [userId], newest first.
  Future<List<FocusSession>> loadAll(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final sessions = decoded
          .whereType<Map>()
          .map((m) => FocusSession.fromJson(m.cast<String, dynamic>()))
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return sessions;
    } catch (_) {
      // Corrupt blob — best to drop the slot than keep raising on load.
      await prefs.remove(_key(userId));
      return const [];
    }
  }

  /// Adds [session] to the local history then tries to mirror it to the
  /// backend. Returns the full session list (newest first) so the caller
  /// can update provider state without reloading.
  Future<List<FocusSession>> save({
    required String userId,
    required FocusSession session,
  }) async {
    final all = [...await loadAll(userId)];
    // Replace if the same id already exists (resume scenario writes the
    // same session twice — once on tick-checkpoint, once on completion).
    final existing = all.indexWhere((s) => s.id == session.id);
    if (existing >= 0) {
      all[existing] = session;
    } else {
      all.insert(0, session);
    }
    all.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final trimmed = all.length > _maxStoredSessions
        ? all.sublist(0, _maxStoredSessions)
        : all;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(userId),
      jsonEncode(trimmed.map((s) => s.toJson()).toList()),
    );

    // Best-effort sync, fire-and-forget — we still return the local list
    // so the UI updates immediately even when offline.
    unawaited(_syncRemote(session));
    return trimmed;
  }

  /// Clears local history for the user. Intended for sign-out / reset.
  Future<void> clearAll(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
  }

  Future<void> _syncRemote(FocusSession session) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) return;
      await http
          .post(
            Uri.parse('${AuthService.apiBaseUrl}/sessions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'mode': session.mode.wireValue,
              'durationSeconds': session.durationSeconds,
              if (session.taskId != null) 'taskId': session.taskId,
              'completed': session.completed,
              'startedAt': session.startedAt.toIso8601String(),
            }),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Swallow — sync is best-effort.
    }
  }
}
