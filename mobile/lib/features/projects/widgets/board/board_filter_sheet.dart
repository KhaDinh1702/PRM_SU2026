import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/theme_service.dart';
import '../../providers/kanban_provider.dart';
import '../../utils/project_board_utils.dart';
import 'board_palette.dart';

/// Bottom sheet that exposes Status / Priority / Assignee filters and the
/// Sort selector for the Kanban board.
class BoardFilterSheet extends StatelessWidget {
  final List<({String id, String name})> assignees;

  const BoardFilterSheet({super.key, required this.assignees});

  static Future<void> show(
    BuildContext context, {
    required KanbanProvider provider,
    required List<({String id, String name})> assignees,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider<KanbanProvider>.value(
        value: provider,
        child: BoardFilterSheet(assignees: assignees),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        decoration: BoxDecoration(
          color: dialogBg.withValues(alpha: 0.95),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.radiusXL),
          ),
          border: Border.all(color: borderColor),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingM,
              AppSizes.paddingS,
              AppSizes.paddingM,
              AppSizes.paddingM,
            ),
            child: Consumer<KanbanProvider>(
              builder: (context, provider, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Handle(color: subTextColor),
                    _HeaderRow(
                      textColor: textColor,
                      subTextColor: subTextColor,
                      hasActiveFilter:
                          provider.hasActiveFilter || provider.query.isNotEmpty,
                      onClear: provider.clearFilters,
                    ),
                    const SizedBox(height: AppSizes.paddingM),
                    _SectionTitle(text: 'Status', color: textColor),
                    const SizedBox(height: AppSizes.paddingS),
                    _StatusChips(provider: provider),
                    const SizedBox(height: AppSizes.paddingM),
                    _SectionTitle(text: 'Priority', color: textColor),
                    const SizedBox(height: AppSizes.paddingS),
                    _PriorityChips(provider: provider),
                    if (assignees.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.paddingM),
                      _SectionTitle(text: 'Assignee', color: textColor),
                      const SizedBox(height: AppSizes.paddingS),
                      _AssigneeChips(
                        provider: provider,
                        assignees: assignees,
                      ),
                    ],
                    const SizedBox(height: AppSizes.paddingM),
                    _SectionTitle(text: 'Sort By', color: textColor),
                    const SizedBox(height: AppSizes.paddingS),
                    _SortChips(provider: provider),
                    const SizedBox(height: AppSizes.paddingM),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSizes.paddingM - 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusM),
                          ),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  final Color color;
  const _Handle({required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        margin: const EdgeInsets.only(top: 6, bottom: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final Color textColor;
  final Color subTextColor;
  final bool hasActiveFilter;
  final VoidCallback onClear;

  const _HeaderRow({
    required this.textColor,
    required this.subTextColor,
    required this.hasActiveFilter,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Filter & Sort',
            style: TextStyle(
              color: textColor,
              fontSize: AppSizes.fontL,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (hasActiveFilter)
          TextButton(
            onPressed: onClear,
            child: const Text(
              'Reset',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final Color color;

  const _SectionTitle({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: AppSizes.fontM - 1,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _StatusChips extends StatelessWidget {
  final KanbanProvider provider;
  const _StatusChips({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.paddingS,
      runSpacing: AppSizes.paddingS,
      children: [
        _OptionChip(
          label: 'All',
          color: BoardPalette.neutral,
          selected: provider.statusFilter == null,
          onTap: () => provider.setStatusFilter(null),
        ),
        for (final column in ProjectBoardUtils.columnOrder)
          _OptionChip(
            label: ProjectBoardUtils.labelFor(column),
            color: BoardPalette.statusColor(column),
            selected: provider.statusFilter == column,
            onTap: () => provider.setStatusFilter(column),
          ),
      ],
    );
  }
}

class _PriorityChips extends StatelessWidget {
  final KanbanProvider provider;
  const _PriorityChips({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.paddingS,
      runSpacing: AppSizes.paddingS,
      children: [
        _OptionChip(
          label: 'All',
          color: BoardPalette.neutral,
          selected: provider.priorityFilter == null,
          onTap: () => provider.setPriorityFilter(null),
        ),
        for (final priority in KanbanPriority.values)
          _OptionChip(
            label: priority.label,
            color: BoardPalette.priorityColor(priority),
            selected: provider.priorityFilter == priority,
            onTap: () => provider.setPriorityFilter(priority),
          ),
      ],
    );
  }
}

class _AssigneeChips extends StatelessWidget {
  final KanbanProvider provider;
  final List<({String id, String name})> assignees;

  const _AssigneeChips({required this.provider, required this.assignees});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.paddingS,
      runSpacing: AppSizes.paddingS,
      children: [
        _OptionChip(
          label: 'All',
          color: BoardPalette.neutral,
          selected: provider.assigneeFilter == null,
          onTap: () => provider.setAssigneeFilter(null),
        ),
        for (final assignee in assignees)
          _OptionChip(
            label: assignee.name.isEmpty ? 'Unknown' : assignee.name,
            color: BoardPalette.assignee,
            selected: provider.assigneeFilter == assignee.id,
            onTap: () => provider.setAssigneeFilter(assignee.id),
          ),
      ],
    );
  }
}

class _SortChips extends StatelessWidget {
  final KanbanProvider provider;
  const _SortChips({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSizes.paddingS,
      runSpacing: AppSizes.paddingS,
      children: [
        for (final option in KanbanSort.values)
          _OptionChip(
            label: option.label,
            color: BoardPalette.sort,
            selected: provider.sort == option,
            onTap: () => provider.setSort(option),
          ),
      ],
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _OptionChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final inactiveText = isDark ? Colors.white70 : Colors.black87;
    final background = selected
        ? color.withValues(alpha: 0.18)
        : (isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.04));
    final border = selected
        ? color.withValues(alpha: 0.55)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08));
    final textColor = selected ? color : inactiveText;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingM - 4,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppSizes.radiusRound),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: AppSizes.fontS + 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
