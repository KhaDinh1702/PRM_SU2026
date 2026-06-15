import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';
import 'project_card.dart';

/// Thanh tìm kiếm project với nút filter.
class ProjectSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  const ProjectSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: captionColor.withOpacity(0.12)),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search projects...',
                hintStyle: TextStyle(color: captionColor),
                prefixIcon:
                    Icon(Icons.search_rounded, color: captionColor, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: onFilterTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.24),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.tune_rounded, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

/// Hiển thị 3 tổng số: tổng / active / cần chú ý.
class ProjectSummary extends StatelessWidget {
  final int totalProjects;
  final int activeProjects;
  final int attentionProjects;

  const ProjectSummary({
    super.key,
    required this.totalProjects,
    required this.activeProjects,
    required this.attentionProjects,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Projects',
            value: totalProjects.toString(),
            color: const Color(0xFF06B6D4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: 'Active',
            value: activeProjects.toString(),
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SummaryTile(
            label: 'Attention',
            value: attentionProjects.toString(),
            color: const Color(0xFFF43F5E),
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.035),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: captionColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab bar lọc danh sách project.
class ProjectTabs extends StatelessWidget {
  final List<String> tabs;
  final String selectedTab;
  final ValueChanged<String> onChanged;

  const ProjectTabs({
    super.key,
    required this.tabs,
    required this.selectedTab,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          final selected = tab == selectedTab;
          return ChoiceChip(
            selected: selected,
            label: Text(
              tab,
              style: TextStyle(
                color: selected ? Colors.white : captionColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            selectedColor: const Color(0xFF06B6D4),
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.04),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF06B6D4)
                  : captionColor.withOpacity(0.16),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            onSelected: (_) => onChanged(tab),
          );
        },
      ),
    );
  }
}

/// Section cuộn ngang hiển thị các project cần chú ý.
class NeedsAttentionSection extends StatelessWidget {
  final List<ProjectCardModel> projects;
  final ValueChanged<ProjectCardModel> onProjectTap;

  const NeedsAttentionSection({
    super.key,
    required this.projects,
    required this.onProjectTap,
  });

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) return const SizedBox.shrink();

    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Needs Attention',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              '${projects.length}',
              style: TextStyle(
                color: captionColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: projects.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final project = projects[index];
              return SizedBox(
                width: 270,
                child: ProjectCard(
                  project: project,
                  compact: true,
                  onTap: () => onProjectTap(project),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet lọc project theo role, type và sort.
class ProjectFilterBottomSheet extends StatelessWidget {
  final String roleFilter;
  final String typeFilter;
  final String sortBy;
  final List<String> roleOptions;
  final List<String> typeOptions;
  final List<String> sortOptions;
  final ValueChanged<String> onRoleChanged;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onSortChanged;
  final VoidCallback onClear;

  const ProjectFilterBottomSheet({
    super.key,
    required this.roleFilter,
    required this.typeFilter,
    required this.sortBy,
    required this.roleOptions,
    required this.typeOptions,
    required this.sortOptions,
    required this.onRoleChanged,
    required this.onTypeChanged,
    required this.onSortChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final dialogBg = ThemeService.getDialogBackgroundColor(isDark);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: dialogBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: captionColor.withOpacity(0.28),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Project filters',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextButton(
                  onPressed: onClear,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _FilterGroup(
              title: 'Role',
              options: roleOptions,
              selected: roleFilter,
              onChanged: onRoleChanged,
            ),
            const SizedBox(height: 16),
            _FilterGroup(
              title: 'Project type',
              options: typeOptions,
              selected: typeFilter,
              onChanged: onTypeChanged,
            ),
            const SizedBox(height: 16),
            _FilterGroup(
              title: 'Sort by',
              options: sortOptions,
              selected: sortBy,
              onChanged: onSortChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterGroup extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final active = option == selected;
            return ChoiceChip(
              selected: active,
              label: Text(
                option,
                style: TextStyle(
                  color: active ? Colors.white : captionColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              selectedColor: const Color(0xFF06B6D4),
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              side: BorderSide(
                color: active
                    ? const Color(0xFF06B6D4)
                    : captionColor.withOpacity(0.14),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (_) => onChanged(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}
