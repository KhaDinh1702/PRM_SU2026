import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth_service.dart';
import '../models/recurrence_rule.dart';

/// Local-only storage for task recurrence rules, scoped to `(userId, taskId)`.
///
/// Backend support for recurrence is out of scope for now — keeping it
/// local-only lets the rest of the engine (model, UI, "spawn next instance"
/// flow) be built and tested without a server change. When the backend
/// catches up, swap the implementation behind this interface.
class RecurrenceService {
  const RecurrenceService();

  Future<String> _key(String taskId) async {
    final user = await AuthService.getUserInfo();
    final userId = (user?['_id'] ?? user?['id'] ?? 'anon').toString();
    return 'task_recurrence_${userId}_$taskId';
  }

  Future<RecurrenceRule?> loadRule(String taskId) async {
    if (taskId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _key(taskId));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return RecurrenceRule.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveRule(String taskId, RecurrenceRule rule) async {
    if (taskId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _key(taskId), jsonEncode(rule.toJson()));
  }

  Future<void> deleteRule(String taskId) async {
    if (taskId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(await _key(taskId));
  }

  /// Convenience: when a recurring task completes, transfer the rule from
  /// the old task ID to the newly-spawned task ID and return the new rule
  /// (unchanged). Returns `null` when [oldTaskId] had no rule.
  Future<RecurrenceRule?> transferRule({
    required String oldTaskId,
    required String newTaskId,
  }) async {
    final rule = await loadRule(oldTaskId);
    if (rule == null) return null;
    await saveRule(newTaskId, rule);
    await deleteRule(oldTaskId);
    return rule;
  }
}
