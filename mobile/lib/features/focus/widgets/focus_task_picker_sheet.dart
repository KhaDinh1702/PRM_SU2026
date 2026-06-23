import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/services/task_service.dart';

/// Bottom sheet that lets the user pick which task they want to focus on.
/// Loads the user's pending tasks once, supports search, and returns a
/// `(taskId, taskTitle)` pair on tap — or `null` if they pick "Không gắn
/// task" / dismiss the sheet.
class FocusTaskPickerSheet extends StatefulWidget {
  const FocusTaskPickerSheet({super.key});

  static Future<FocusTaskPickResult?> show(BuildContext context) {
    return showModalBottomSheet<FocusTaskPickResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FocusTaskPickerSheet(),
    );
  }

  @override
  State<FocusTaskPickerSheet> createState() => _FocusTaskPickerSheetState();
}

/// Result returned by the picker. `id` is null when the user explicitly
/// chooses to clear the task from the active session.
class FocusTaskPickResult {
  final String? id;
  final String? title;
  const FocusTaskPickResult({this.id, this.title});
  const FocusTaskPickResult.cleared() : id = null, title = null;
}

class _FocusTaskPickerSheetState extends State<FocusTaskPickerSheet> {
  final TaskService _taskService = const TaskService();
  final TextEditingController _searchController = TextEditingController();

  List<TaskModel> _tasks = const [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await _taskService.getTasks(
        tab: 'all',
        statusFilter: 'Pending',
      );
      if (!mounted) return;
      setState(() {
        _tasks = list;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _tasks = const [];
        _loading = false;
      });
    }
  }

  List<TaskModel> get _filtered {
    if (_query.isEmpty) return _tasks;
    final q = _query.toLowerCase();
    return _tasks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final bg = ThemeService.getDialogBackgroundColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    final filtered = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: captionColor.withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Row(
                  children: [
                    Text(
                      LocaleService.tr('Chọn task', en: 'Pick a task'),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => Navigator.pop(
                        context,
                        const FocusTaskPickResult.cleared(),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: Text(LocaleService.tr('Bỏ chọn', en: 'Clear')),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: LocaleService.tr('Tìm task...',
                        en: 'Search tasks...'),
                    hintStyle: TextStyle(color: captionColor),
                    isDense: true,
                    prefixIcon: Icon(Icons.search_rounded, color: captionColor),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.black.withValues(alpha: 0.03),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              LocaleService.tr(
                                'Không có task nào phù hợp',
                                en: 'No matching tasks',
                              ),
                              style: TextStyle(color: captionColor),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemBuilder: (context, index) {
                              final task = filtered[index];
                              return _TaskRow(
                                title: task.title.isEmpty
                                    ? LocaleService.tr(
                                        'Task chưa đặt tên',
                                        en: 'Untitled task',
                                      )
                                    : task.title,
                                subtitle: task.priorityLabel,
                                tint: task.priorityColor,
                                onTap: () => Navigator.pop(
                                  context,
                                  FocusTaskPickResult(
                                    id: task.id,
                                    title: task.title,
                                  ),
                                ),
                              );
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemCount: filtered.length,
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TaskRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;

  const _TaskRow({
    required this.title,
    required this.subtitle,
    required this.tint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: tint,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: captionColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_arrow_rounded, color: tint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
