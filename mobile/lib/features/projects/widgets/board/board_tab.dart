import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/locale_service.dart';
import '../../../../services/theme_service.dart';
import '../../../tasks/models/task_model.dart';
import '../../providers/kanban_provider.dart';
import '../../utils/project_board_utils.dart';
import 'board_empty_state.dart';
import 'board_filter_sheet.dart';
import 'board_palette.dart';
import 'board_section.dart';
import 'board_task_card.dart';

/// Mobile-first Kanban board for the Project Detail screen.
///
/// The widget owns the *presentation* of the board only — task data, status
/// mutations and the create / edit dialogs continue to live in the parent
/// (`ProjectScreen`). Search, filter, sort and accordion state are owned by an
/// internally-scoped [KanbanProvider] so the rest of the screen does not need
/// to know about them.
class BoardTab extends StatelessWidget {
  final List<TaskModel> tasks;
  final Set<String> reviewTaskIds;
  final bool isLoading;
  final bool tasksLoaded;
  final String Function(Map<String, dynamic>? assignee) assigneeName;
  final bool Function(TaskModel task) canUpdateTask;
  final void Function(TaskModel task) onOpenTask;
  final void Function(TaskModel task) onMarkComplete;
  final void Function(TaskModel task) onMoveToNextStatus;
  final VoidCallback onLoadTasks;

  /// Optional. When supplied, a Floating Action Button is shown that
  /// delegates task creation to the parent screen (which already owns the
  /// "Create Task" bottom sheet).
  final VoidCallback? onCreateTask;

  /// Optional. Long-press handler. Falls back to [onOpenTask] when omitted.
  final void Function(TaskModel task)? onLongPressTask;

  const BoardTab({
    super.key,
    required this.tasks,
    required this.reviewTaskIds,
    required this.isLoading,
    required this.tasksLoaded,
    required this.assigneeName,
    required this.canUpdateTask,
    required this.onOpenTask,
    required this.onMarkComplete,
    required this.onMoveToNextStatus,
    required this.onLoadTasks,
    this.onCreateTask,
    this.onLongPressTask,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<KanbanProvider>(
      create: (_) => KanbanProvider(),
      child: _BoardTabBody(
        tasks: tasks,
        reviewTaskIds: reviewTaskIds,
        isLoading: isLoading,
        tasksLoaded: tasksLoaded,
        assigneeName: assigneeName,
        canUpdateTask: canUpdateTask,
        onOpenTask: onOpenTask,
        onLongPressTask: onLongPressTask ?? onOpenTask,
        onMarkComplete: onMarkComplete,
        onMoveToNextStatus: onMoveToNextStatus,
        onLoadTasks: onLoadTasks,
        onCreateTask: onCreateTask,
      ),
    );
  }
}

class _BoardTabBody extends StatefulWidget {
  final List<TaskModel> tasks;
  final Set<String> reviewTaskIds;
  final bool isLoading;
  final bool tasksLoaded;
  final String Function(Map<String, dynamic>? assignee) assigneeName;
  final bool Function(TaskModel task) canUpdateTask;
  final void Function(TaskModel task) onOpenTask;
  final void Function(TaskModel task) onLongPressTask;
  final void Function(TaskModel task) onMarkComplete;
  final void Function(TaskModel task) onMoveToNextStatus;
  final VoidCallback onLoadTasks;
  final VoidCallback? onCreateTask;

  const _BoardTabBody({
    required this.tasks,
    required this.reviewTaskIds,
    required this.isLoading,
    required this.tasksLoaded,
    required this.assigneeName,
    required this.canUpdateTask,
    required this.onOpenTask,
    required this.onLongPressTask,
    required this.onMarkComplete,
    required this.onMoveToNextStatus,
    required this.onLoadTasks,
    required this.onCreateTask,
  });

  @override
  State<_BoardTabBody> createState() => _BoardTabBodyState();
}

class _BoardTabBodyState extends State<_BoardTabBody> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!widget.tasksLoaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onLoadTasks());
    }

    final provider = context.watch<KanbanProvider>();
    final grouped = provider.groupTasks(widget.tasks, widget.reviewTaskIds);
    final totalVisible = grouped.values.fold<int>(0, (sum, l) => sum + l.length);
    final hasAnyTask = widget.tasks.isNotEmpty;

    return Column(
      children: [
        _BoardToolbar(
              controller: _searchController,
              onSearchChanged: provider.setQuery,
              onClearSearch: () {
                _searchController.clear();
                provider.setQuery('');
              },
              onOpenFilter: () => BoardFilterSheet.show(
                context,
                provider: provider,
                assignees: provider.assigneeOptions(
                  widget.tasks,
                  widget.assigneeName,
                ),
              ),
              activeFilters: provider.activeFilterCount,
              currentSort: provider.sort,
              onSortChanged: provider.setSort,
            ),
            Expanded(
              child: !hasAnyTask
                  ? BoardEmptyState(
                      title: LocaleService.tr(
                          'Dự án chưa có task nào',
                          en: 'No tasks in this project'),
                      subtitle: LocaleService.tr(
                          'Tạo task đầu tiên',
                          en: 'Create your first task'),
                      ctaLabel: widget.onCreateTask != null
                          ? LocaleService.tr('Tạo task', en: 'Create Task')
                          : null,
                      onCta: widget.onCreateTask,
                    )
                  : totalVisible == 0
                      ? BoardEmptyState(
                          title: LocaleService.tr('Không khớp',
                              en: 'No matches'),
                          subtitle: LocaleService.tr(
                              'Thử tìm khác hoặc xoá bộ lọc.',
                              en: 'Try a different search or clear the filters.'),
                          emoji: '🔍',
                          ctaLabel: LocaleService.tr('Xoá bộ lọc',
                              en: 'Clear filters'),
                          onCta: () {
                            _searchController.clear();
                            provider.clearFilters();
                          },
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSizes.paddingM,
                            AppSizes.paddingS + 4,
                            AppSizes.paddingM,
                            100,
                          ),
                          children: [
                            for (final column
                                in ProjectBoardUtils.columnOrder)
                              BoardSection(
                                title: ProjectBoardUtils.labelFor(column),
                                count: grouped[column]!.length,
                                color: BoardPalette.statusColor(column),
                                isExpanded: provider.isExpanded(column),
                                onToggle: () =>
                                    provider.toggleExpanded(column),
                                emptyState: BoardEmptyState(
                                  title: LocaleService.tr(
                                      'Cột này chưa có task',
                                      en: 'No tasks in this column'),
                                  subtitle: widget.onCreateTask != null
                                      ? LocaleService.tr(
                                          'Tạo task đầu tiên',
                                          en: 'Create your first task')
                                      : LocaleService.tr(
                                          'Kéo task vào đây khi bắt đầu làm.',
                                          en: 'Drag tasks here as you work.'),
                                  ctaLabel: widget.onCreateTask != null
                                      ? LocaleService.tr('Tạo task',
                                          en: 'Create Task')
                                      : null,
                                  onCta: widget.onCreateTask,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.paddingM,
                                    vertical: AppSizes.paddingL,
                                  ),
                                ),
                                children: grouped[column]!
                                    .map(
                                      (task) => _buildCard(task, column),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
            ),
      ],
    );
  }

  Widget _buildCard(TaskModel task, BoardColumn column) {
    final canUpdate = widget.canUpdateTask(task);
    return BoardTaskCard(
      task: task,
      column: column,
      assigneeName: widget.assigneeName(task.assignedTo),
      canSwipe: canUpdate,
      onTap: () => widget.onOpenTask(task),
      onLongPress: () => widget.onLongPressTask(task),
      onSwipeComplete: canUpdate ? () => widget.onMarkComplete(task) : null,
      onSwipeAdvance: canUpdate ? () => widget.onMoveToNextStatus(task) : null,
    );
  }
}

class _BoardToolbar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onOpenFilter;
  final int activeFilters;
  final KanbanSort currentSort;
  final ValueChanged<KanbanSort> onSortChanged;

  const _BoardToolbar({
    required this.controller,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onOpenFilter,
    required this.activeFilters,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.paddingM,
        AppSizes.paddingM - 4,
        AppSizes.paddingM,
        AppSizes.paddingS,
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: AppSizes.inputHeight - 8,
              child: TextField(
                controller: controller,
                onChanged: onSearchChanged,
                style: TextStyle(color: textColor, fontSize: AppSizes.fontM),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: LocaleService.tr('Tìm task', en: 'Search tasks'),
                  hintStyle: TextStyle(
                    color: subTextColor,
                    fontSize: AppSizes.fontM,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: subTextColor,
                    size: 20,
                  ),
                  suffixIcon: controller.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: subTextColor,
                            size: 18,
                          ),
                          onPressed: onClearSearch,
                          splashRadius: 18,
                        ),
                  filled: true,
                  fillColor: fillColor,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM - 4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusRound),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusRound),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusRound),
                    borderSide:
                        const BorderSide(color: BoardPalette.sort, width: 1.2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.paddingS),
          _ToolbarIconButton(
            icon: Icons.tune_rounded,
            badge: activeFilters,
            onTap: onOpenFilter,
            tooltip: LocaleService.tr('Bộ lọc', en: 'Filter'),
          ),
          const SizedBox(width: AppSizes.paddingS - 2),
          _SortMenuButton(
            currentSort: currentSort,
            onSortChanged: onSortChanged,
          ),
        ],
      ),
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;
  final String tooltip;

  const _ToolbarIconButton({
    required this.icon,
    required this.badge,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.radiusRound),
          onTap: onTap,
          child: Container(
            height: AppSizes.inputHeight - 8,
            width: AppSizes.inputHeight - 8,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fillColor,
              border: Border.all(color: borderColor),
              shape: BoxShape.circle,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(child: Icon(icon, color: textColor, size: 20)),
                if (badge > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: BoardPalette.high,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusRound),
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SortMenuButton extends StatelessWidget {
  final KanbanSort currentSort;
  final ValueChanged<KanbanSort> onSortChanged;

  const _SortMenuButton({
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return PopupMenuButton<KanbanSort>(
      tooltip: LocaleService.tr('Sắp xếp', en: 'Sort by'),
      initialValue: currentSort,
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        for (final option in KanbanSort.values)
          PopupMenuItem<KanbanSort>(
            value: option,
            child: Row(
              children: [
                Icon(
                  option == currentSort
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: option == currentSort
                      ? BoardPalette.sort
                      : textColor.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 10),
                Text(option.label),
              ],
            ),
          ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusM),
      ),
      child: Container(
        height: AppSizes.inputHeight - 8,
        width: AppSizes.inputHeight - 8,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fillColor,
          border: Border.all(color: borderColor),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.sort_rounded, color: textColor, size: 20),
      ),
    );
  }
}
