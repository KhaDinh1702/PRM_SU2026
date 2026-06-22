import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth_service.dart';
import '../models/checklist_item.dart';

/// Local-only storage for per-task checklists, scoped to `(userId, taskId)`.
class ChecklistService {
  const ChecklistService();

  Future<String> _key(String taskId) async {
    final user = await AuthService.getUserInfo();
    final userId = (user?['_id'] ?? user?['id'] ?? 'anon').toString();
    return 'task_checklist_${userId}_$taskId';
  }

  Future<List<ChecklistItem>> loadItems(String taskId) async {
    if (taskId.isEmpty) return const [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _key(taskId));
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(ChecklistItem.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveItems(String taskId, List<ChecklistItem> items) async {
    if (taskId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map((i) => i.toJson()).toList());
    await prefs.setString(await _key(taskId), encoded);
  }

  Future<void> deleteAll(String taskId) async {
    if (taskId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(await _key(taskId));
  }

  /// Convenience: just the (done, total) summary without exposing each item.
  Future<ChecklistProgress> loadProgress(String taskId) async {
    final items = await loadItems(taskId);
    if (items.isEmpty) return ChecklistProgress.empty;
    final done = items.where((i) => i.isDone).length;
    return ChecklistProgress(done: done, total: items.length);
  }
}
