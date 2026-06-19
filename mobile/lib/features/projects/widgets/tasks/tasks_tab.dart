import 'package:flutter/material.dart';
import '../../../../services/theme_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../utils/task_display.dart';
import '../project_shared.dart';

/// Tab danh sách task của project với filter và popup action.
class TasksTab extends StatelessWidget {
  final List<dynamic> tasks;
  final String selectedFilter;
  final bool isLoading;
  final bool tasksLoaded;
  final bool canManage;
  final bool canAddTask;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onAddTask;
  final VoidCallback onLoadTasks;
  final String Function(dynamic assignee) assigneeName;
  final bool Function(dynamic task) canUpdateTask;
  final void Function(dynamic task) onEditTask;
  final void Function(dynamic task, String status) onUpdateStatus;

  const TasksTab({
    super.key,
    required this.tasks,
    required this.selectedFilter,
    required this.isLoading,
    required this.tasksLoaded,
    required this.canManage,
    required this.canAddTask,
    required this.onFilterChanged,
    required this.onAddTask,
    required this.onLoadTasks,
    required this.assigneeName,
    required this.canUpdateTask,
    required this.onEditTask,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final filteredTasks = tasks.where((task) {
      final status = (task['status'] ?? 'Pending').toString();
      if (selectedFilter == 'To Do') return status == 'Pending';
      if (selectedFilter == 'Done') return status == 'Completed';
      if (selectedFilter == 'In Progress') return status == 'In Progress';
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingM + 4.0,
            AppSizes.paddingM,
            AppSizes.paddingM + 4.0,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppSizes.chipHeight - 4.0,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final filter =
                          ['All', 'To Do', 'In Progress', 'Done'][index];
                      final selected = filter == selectedFilter;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(filter),
                        selectedColor: AppColors.taskAccent,
                        labelStyle: TextStyle(
                            color: selected ? Colors.white : captionColor,
                            fontSize: AppSizes.fontS,
                            fontWeight: FontWeight.w800),
                        onSelected: (_) => onFilterChanged(filter),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: AppSizes.paddingS),
                    itemCount: 4,
                  ),
                ),
              ),
              if (canAddTask) ...[
                const SizedBox(width: AppSizes.paddingS),
                IconButton(
                  onPressed: onAddTask,
                  icon: const Icon(Icons.add_task_rounded),
                  color: AppColors.taskAccent,
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : tasks.isEmpty
                  ? ProjectEmptyState(
                      icon: Icons.task_alt_rounded,
                      title: 'No tasks yet',
                      text:
                          'Create tasks to break this project into manageable work.',
                      cta: canAddTask ? 'Add task' : null,
                      onPressed: canAddTask ? onAddTask : null,
                    )
                  : filteredTasks.isEmpty
                      ? const ProjectEmptyState(
                          icon: Icons.filter_alt_off_rounded,
                          title: 'No tasks in this filter',
                          text: 'Try a different task status.',
                          cta: null,
                          onPressed: null,
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(AppSizes.paddingM + 4.0),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final status =
                                (task['status'] ?? 'Pending').toString();
                            final priority =
                                (task['priority'] ?? 'Medium').toString();
                            final assignee = task['assignedTo'] ?? task['user'];
                            final overdue = taskIsVisuallyOverdue(task);
                            final color = overdue
                                ? AppColors.error
                                : taskStatusColor(status);
                            final reminderLabel = taskReminderLabel(task);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSizes.paddingS + 4.0),
                              child: ProjectDetailCard(
                                padding: const EdgeInsets.all(AppSizes.paddingM - 2.0),
                                borderColor: color.withValues(alpha: 0.24),
                                child: Row(
                                  children: [
                                    Icon(
                                      status == 'Completed'
                                          ? Icons.check_circle_rounded
                                          : Icons
                                              .radio_button_unchecked_rounded,
                                      color: color,
                                    ),
                                    const SizedBox(width: AppSizes.paddingS + 4.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task['title'] ?? 'Untitled task',
                                            style: TextStyle(
                                              color: textColor,
                                              fontWeight: FontWeight.w900,
                                              fontSize: AppSizes.fontM,
                                            ),
                                          ),
                                          const SizedBox(height: AppSizes.paddingS - 3.0),
                                          Text(
                                            '${taskDueText(task)} · ${assigneeName(assignee)}',
                                            style: TextStyle(
                                                color: captionColor,
                                                fontSize: AppSizes.fontS),
                                          ),
                                          const SizedBox(height: AppSizes.paddingS),
                                          Wrap(
                                            spacing: AppSizes.paddingS - 1.0,
                                            runSpacing: AppSizes.paddingS - 2.0,
                                            children: [
                                              ProjectStatusPill(
                                                label: overdue
                                                    ? 'Overdue'
                                                    : status,
                                                color: color,
                                              ),
                                              ProjectStatusPill(
                                                label: priority,
                                                color: taskPriorityColor(
                                                    priority),
                                              ),
                                              if (reminderLabel.isNotEmpty)
                                                ProjectStatusPill(
                                                  label: reminderLabel,
                                                  color: AppColors.dashboardAccent,
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (canUpdateTask(task))
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert_rounded,
                                            color: captionColor),
                                        onSelected: (value) {
                                          if (value == '__edit') {
                                            onEditTask(task);
                                          } else {
                                            onUpdateStatus(task, value);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          if (canManage)
                                            const PopupMenuItem(
                                              value: '__edit',
                                              child: Text('Edit'),
                                            ),
                                          if (canManage)
                                            const PopupMenuDivider(),
                                          ...[
                                            'Pending',
                                            'In Progress',
                                            'Completed',
                                          ].map((value) => PopupMenuItem(
                                                value: value,
                                                child: Text(value),
                                              )),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
