import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/auth_service.dart';
import '../models/task_tag.dart';

/// Local-only tag definitions + per-task tag assignments, scoped per user.
///
/// Two storage slots:
///  - `task_tag_catalog_<userId>` → `List<TaskTag>` (the user's tag library)
///  - `task_tag_assign_<userId>_<taskId>` → `List<String>` (tag ids on a task)
class TagService {
  const TagService();

  Future<String> _userId() async {
    final user = await AuthService.getUserInfo();
    return (user?['_id'] ?? user?['id'] ?? 'anon').toString();
  }

  Future<String> _catalogKey() async {
    return 'task_tag_catalog_${await _userId()}';
  }

  Future<String> _assignKey(String taskId) async {
    return 'task_tag_assign_${await _userId()}_$taskId';
  }

  // --- Catalog (the user's tag library) ---

  Future<List<TaskTag>> loadCatalog() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _catalogKey());
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(TaskTag.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveCatalog(List<TaskTag> tags) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(tags.map((t) => t.toJson()).toList());
    await prefs.setString(await _catalogKey(), encoded);
  }

  Future<TaskTag> createTag({
    required String name,
    required int colorValue,
  }) async {
    final catalog = await loadCatalog();
    final tag = TaskTag(
      id: 'tag:${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      colorValue: colorValue,
    );
    final updated = [...catalog, tag];
    await saveCatalog(updated);
    return tag;
  }

  Future<void> updateTag(TaskTag tag) async {
    final catalog = await loadCatalog();
    final updated =
        catalog.map((t) => t.id == tag.id ? tag : t).toList(growable: false);
    await saveCatalog(updated);
  }

  Future<void> deleteTag(String tagId) async {
    final catalog = await loadCatalog();
    final updated = catalog.where((t) => t.id != tagId).toList();
    await saveCatalog(updated);
    // Note: assignments referencing this tag are pruned lazily on next load.
  }

  // --- Assignments per task ---

  Future<List<String>> loadAssignedIds(String taskId) async {
    if (taskId.isEmpty) return const [];
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(await _assignKey(taskId));
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAssignedIds(String taskId, List<String> ids) async {
    if (taskId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(await _assignKey(taskId), jsonEncode(ids));
  }

  /// Loads the [TaskTag] objects assigned to a given task, dropping any ids
  /// that no longer exist in the catalog (e.g. tag was deleted).
  Future<List<TaskTag>> loadAssignedTags(String taskId) async {
    final assignedIds = await loadAssignedIds(taskId);
    if (assignedIds.isEmpty) return const [];
    final catalog = await loadCatalog();
    final byId = {for (final t in catalog) t.id: t};
    return assignedIds
        .map((id) => byId[id])
        .whereType<TaskTag>()
        .toList(growable: false);
  }
}
