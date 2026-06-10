part of project_screen;

class ProjectCardModel {
  final dynamic raw;
  final String name;
  final String status;
  final String subtitle;
  final String nextAction;
  final int progress;
  final int completedTasks;
  final int totalTasks;
  final int memberCount;
  final String role;
  final String type;
  final String dueText;
  final String attentionReason;
  final Color accentColor;
  final bool needsAttention;

  const ProjectCardModel({
    required this.raw,
    required this.name,
    required this.status,
    required this.subtitle,
    required this.nextAction,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.memberCount,
    required this.role,
    required this.type,
    required this.dueText,
    required this.attentionReason,
    required this.accentColor,
    required this.needsAttention,
  });
}

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

class ProjectCard extends StatelessWidget {
  final ProjectCardModel project;
  final bool compact;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final bgColor = isDark
        ? const Color(0xFF101827).withOpacity(0.86)
        : Colors.white.withOpacity(0.92);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: project.accentColor.withOpacity(0.28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: project.accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  bottomLeft: Radius.circular(18),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, compact ? 12 : 15, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: compact ? 15 : 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _StatusPill(
                          label: project.status,
                          color: project.accentColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      project.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: project.needsAttention
                            ? project.accentColor
                            : subTextColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Next: ${project.nextAction}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: captionColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: project.progress / 100,
                              minHeight: 7,
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.black.withOpacity(0.06),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                project.accentColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${project.progress}%',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    if (!compact) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _MetaItem(
                            icon: Icons.check_circle_outline_rounded,
                            label:
                                '${project.completedTasks}/${project.totalTasks} tasks',
                            color: captionColor,
                          ),
                          _MetaItem(
                            icon: Icons.people_outline_rounded,
                            label: '${project.memberCount} members',
                            color: captionColor,
                          ),
                          _MetaItem(
                            icon: Icons.verified_user_outlined,
                            label: project.role,
                            color: captionColor,
                          ),
                          if (project.dueText.isNotEmpty)
                            _MetaItem(
                              icon: Icons.event_rounded,
                              label: project.dueText,
                              color: project.accentColor,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

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

class ProjectDetailHeader extends StatelessWidget {
  final String name;
  final String description;
  final String role;
  final String workStatus;
  final int memberCount;
  final int progress;
  final int completedTasks;
  final int totalTasks;
  final Color statusColor;
  final bool canShowMenu;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProjectDetailHeader({
    super.key,
    required this.name,
    required this.description,
    required this.role,
    required this.workStatus,
    required this.memberCount,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.statusColor,
    required this.canShowMenu,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    final progressText = totalTasks == 0
        ? 'No tasks yet'
        : '$progress% complete · $completedTasks of $totalTasks tasks done';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: captionColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: subTextColor,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    '$role · $workStatus · $memberCount members',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: captionColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (canShowMenu)
              ProjectActionMenu(
                onEdit: onEdit,
                onDelete: onDelete,
              ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress / 100,
            minHeight: 7,
            backgroundColor: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.06),
            valueColor: AlwaysStoppedAnimation(statusColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          progressText,
          style: TextStyle(
            color: totalTasks == 0 ? captionColor : statusColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class ProjectActionMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProjectActionMenu({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (value) {
        if (value == 'edit') onEdit();
        if (value == 'delete') onDelete();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Edit project')),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child:
              Text('Delete project', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    );
  }
}

class OverviewTab extends StatelessWidget {
  final String description;
  final String actionTitle;
  final String actionText;
  final String actionLabel;
  final Color actionColor;
  final VoidCallback onAction;
  final int progress;
  final int completedTasks;
  final int totalTasks;
  final int memberCount;
  final String role;
  final String workStatus;
  final Color workStatusColor;

  const OverviewTab({
    super.key,
    required this.description,
    required this.actionTitle,
    required this.actionText,
    required this.actionLabel,
    required this.actionColor,
    required this.onAction,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.memberCount,
    required this.role,
    required this.workStatus,
    required this.workStatusColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        _DetailCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                description.isEmpty ? 'No detailed description.' : description,
                style:
                    TextStyle(color: subTextColor, fontSize: 13, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        NextActionCard(
          title: actionTitle,
          text: actionText,
          ctaLabel: actionLabel,
          color: actionColor,
          onPressed: onAction,
        ),
        const SizedBox(height: 12),
        ProgressSummaryCard(
          progress: progress,
          completedTasks: completedTasks,
          totalTasks: totalTasks,
          color: workStatusColor,
        ),
        const SizedBox(height: 12),
        ProjectInfoGrid(
          completedTasks: completedTasks,
          totalTasks: totalTasks,
          memberCount: memberCount,
          role: role,
          workStatus: workStatus,
          workStatusColor: workStatusColor,
        ),
        const SizedBox(height: 12),
        RecentActivityCard(
          text: totalTasks == 0
              ? 'Project created. No tasks have been added yet.'
              : 'Progress is based on the latest task updates.',
        ),
      ],
    );
  }
}

class NextActionCard extends StatelessWidget {
  final String title;
  final String text;
  final String ctaLabel;
  final Color color;
  final VoidCallback onPressed;

  const NextActionCard({
    super.key,
    required this.title,
    required this.text,
    required this.ctaLabel,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);

    return _DetailCard(
      borderColor: color.withOpacity(0.32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.bolt_rounded, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(text,
                    style: TextStyle(
                        color: subTextColor, fontSize: 12, height: 1.3)),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onPressed,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(ctaLabel,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w900,
                          fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProgressSummaryCard extends StatelessWidget {
  final int progress;
  final int completedTasks;
  final int totalTasks;
  final Color color;

  const ProgressSummaryCard({
    super.key,
    required this.progress,
    required this.completedTasks,
    required this.totalTasks,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress summary',
                  style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w900)),
              Text('$progress%',
                  style: TextStyle(
                      color: color, fontSize: 18, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.black.withOpacity(0.06),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalTasks == 0
                ? 'No tasks yet'
                : '$completedTasks of $totalTasks tasks completed',
            style: TextStyle(color: captionColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class ProjectInfoGrid extends StatelessWidget {
  final int completedTasks;
  final int totalTasks;
  final int memberCount;
  final String role;
  final String workStatus;
  final Color workStatusColor;

  const ProjectInfoGrid({
    super.key,
    required this.completedTasks,
    required this.totalTasks,
    required this.memberCount,
    required this.role,
    required this.workStatus,
    required this.workStatusColor,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.45,
      children: [
        _InfoTile(label: 'Tasks', value: '$completedTasks/$totalTasks'),
        _InfoTile(label: 'Members', value: '$memberCount'),
        _InfoTile(label: 'Role', value: role),
        _InfoTile(
            label: 'Project Status', value: workStatus, color: workStatusColor),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoTile({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return _DetailCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(color: captionColor, fontSize: 10)),
          const SizedBox(height: 4),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: color ?? textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class RecentActivityCard extends StatelessWidget {
  final String text;

  const RecentActivityCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    return _DetailCard(
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: captionColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child:
                Text(text, style: TextStyle(color: captionColor, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class TasksTab extends StatelessWidget {
  final List<dynamic> tasks;
  final String selectedFilter;
  final bool isLoading;
  final bool tasksLoaded;
  final bool canManage;
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final filter =
                          ['All', 'To Do', 'In Progress', 'Done'][index];
                      final selected = filter == selectedFilter;
                      return ChoiceChip(
                        selected: selected,
                        label: Text(filter),
                        selectedColor: const Color(0xFF06B6D4),
                        labelStyle: TextStyle(
                            color: selected ? Colors.white : captionColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w800),
                        onSelected: (_) => onFilterChanged(filter),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: 4,
                  ),
                ),
              ),
              if (canManage) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: onAddTask,
                  icon: const Icon(Icons.add_task_rounded),
                  color: const Color(0xFF06B6D4),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : tasks.isEmpty
                  ? _EmptyState(
                      icon: Icons.task_alt_rounded,
                      title: 'No tasks yet',
                      text:
                          'Create tasks to break this project into manageable work.',
                      cta: canManage ? 'Add task' : null,
                      onPressed: canManage ? onAddTask : null,
                    )
                  : filteredTasks.isEmpty
                      ? _EmptyState(
                          icon: Icons.filter_alt_off_rounded,
                          title: 'No tasks in this filter',
                          text: 'Try a different task status.',
                          cta: null,
                          onPressed: null,
                        )
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredTasks.length,
                          itemBuilder: (context, index) {
                            final task = filteredTasks[index];
                            final status =
                                (task['status'] ?? 'Pending').toString();
                            final priority =
                                (task['priority'] ?? 'Medium').toString();
                            final assignee = task['assignedTo'] ?? task['user'];
                            final overdue = _taskIsVisuallyOverdue(task);
                            final color = overdue
                                ? const Color(0xFFF43F5E)
                                : _taskStatusColor(status);
                            final reminderLabel = _taskReminderLabel(task);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _DetailCard(
                                padding: const EdgeInsets.all(14),
                                borderColor: color.withOpacity(0.24),
                                child: Row(
                                  children: [
                                    Icon(
                                      status == 'Completed'
                                          ? Icons.check_circle_rounded
                                          : Icons
                                              .radio_button_unchecked_rounded,
                                      color: color,
                                    ),
                                    const SizedBox(width: 12),
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
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            '${_taskDueText(task)} · ${assigneeName(assignee)}',
                                            style: TextStyle(
                                                color: captionColor,
                                                fontSize: 11),
                                          ),
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 7,
                                            runSpacing: 6,
                                            children: [
                                              _StatusPill(
                                                label: overdue
                                                    ? 'Overdue'
                                                    : status,
                                                color: color,
                                              ),
                                              _StatusPill(
                                                label: priority,
                                                color: _taskPriorityColor(
                                                    priority),
                                              ),
                                              if (reminderLabel.isNotEmpty)
                                                _StatusPill(
                                                  label: reminderLabel,
                                                  color:
                                                      const Color(0xFF8B5CF6),
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

class MembersTab extends StatelessWidget {
  final List<dynamic> owners;
  final List<dynamic> managers;
  final List<dynamic> members;
  final bool canInvite;
  final bool canEditRoles;
  final VoidCallback onInvite;
  final Future<void> Function(dynamic user, String role) onRoleChanged;

  const MembersTab({
    super.key,
    required this.owners,
    required this.managers,
    required this.members,
    required this.canInvite,
    required this.canEditRoles,
    required this.onInvite,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        if (canInvite)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onInvite,
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text('Invite member'),
            ),
          ),
        _MemberGroup(
          title: 'Owner',
          users: owners,
          role: 'Owner',
          canEditRoles: false,
          onRoleChanged: onRoleChanged,
        ),
        _MemberGroup(
          title: 'Managers',
          users: managers,
          role: 'Manager',
          canEditRoles: canEditRoles,
          onRoleChanged: onRoleChanged,
        ),
        _MemberGroup(
          title: 'Members',
          users: members,
          role: 'Member',
          canEditRoles: canEditRoles,
          onRoleChanged: onRoleChanged,
        ),
      ],
    );
  }
}

class _MemberGroup extends StatelessWidget {
  final String title;
  final List<dynamic> users;
  final String role;
  final bool canEditRoles;
  final Future<void> Function(dynamic user, String role) onRoleChanged;

  const _MemberGroup({
    required this.title,
    required this.users,
    required this.role,
    required this.canEditRoles,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    if (users.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(title,
              style: TextStyle(
                  color: captionColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2)),
        ),
        ...users.map((user) {
          final name = user is Map<String, dynamic>
              ? ((user['name'] ?? '').toString().isNotEmpty
                  ? user['name'].toString()
                  : (user['email'] ?? 'Member').toString().split('@').first)
              : 'Member';
          final email = user is Map<String, dynamic>
              ? (user['email'] ?? '').toString()
              : '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DetailCard(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: role == 'Owner'
                        ? const Color(0xFFEAB308)
                        : role == 'Manager'
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF06B6D4),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                                color: textColor, fontWeight: FontWeight.w900)),
                        if (email.isNotEmpty)
                          Text(email,
                              style:
                                  TextStyle(color: captionColor, fontSize: 11)),
                      ],
                    ),
                  ),
                  canEditRoles
                      ? _RoleEditButton(
                          user: user,
                          role: role,
                          onRoleChanged: onRoleChanged,
                        )
                      : _StatusPill(
                          label: role,
                          color: role == 'Owner'
                              ? const Color(0xFFEAB308)
                              : role == 'Manager'
                                  ? const Color(0xFF8B5CF6)
                                  : const Color(0xFF06B6D4),
                        ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _RoleEditButton extends StatelessWidget {
  final dynamic user;
  final String role;
  final Future<void> Function(dynamic user, String role) onRoleChanged;

  const _RoleEditButton({
    required this.user,
    required this.role,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        role == 'Manager' ? const Color(0xFF8B5CF6) : const Color(0xFF06B6D4);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _showEditRoleDialog(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusPill(label: role, color: color),
          const SizedBox(width: 4),
          Icon(Icons.edit_rounded, size: 15, color: color),
        ],
      ),
    );
  }

  void _showEditRoleDialog(BuildContext context) {
    String selectedRole = role == 'Manager' ? 'Manager' : 'Member';
    var saving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = ThemeService.isDarkMode.value;
            final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
            final textColor = ThemeService.getTextColor(isDark);
            final subTextColor = ThemeService.getSubTextColor(isDark);

            return AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'Edit role',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose this member role in the project.',
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const ['Manager', 'Member']
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setDialogState(() => selectedRole = value);
                            }
                          },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setDialogState(() => saving = true);
                          await onRoleChanged(user, selectedRole);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ChatTab extends StatelessWidget {
  final VoidCallback onOpenChat;

  const ChatTab({super.key, required this.onOpenChat});

  @override
  Widget build(BuildContext context) {
    return _EmptyState(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'No messages yet',
      text: 'Start discussing this project with your team.',
      cta: 'Open chat',
      ctaIcon: Icons.chat_bubble_rounded,
      onPressed: onOpenChat,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String? cta;
  final IconData? ctaIcon;
  final VoidCallback? onPressed;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.text,
    required this.cta,
    this.ctaIcon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: subTextColor.withOpacity(0.65)),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(text,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: subTextColor, fontSize: 13, height: 1.35)),
            if (cta != null && onPressed != null) ...[
              const SizedBox(height: 16),
              PremiumButton.icon(
                onPressed: onPressed!,
                icon: ctaIcon ?? Icons.add_rounded,
                label: cta!,
                backgroundColor: const Color(0xFF06B6D4),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const _DetailCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.055)
            : Colors.black.withOpacity(0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor ??
              (isDark
                  ? Colors.white.withOpacity(0.075)
                  : Colors.black.withOpacity(0.06)),
        ),
      ),
      child: child,
    );
  }
}

Color _taskStatusColor(String status) {
  if (status == 'Completed') return const Color(0xFF10B981);
  if (status == 'In Progress') return const Color(0xFF06B6D4);
  return Colors.blueGrey;
}

Color _taskPriorityColor(String priority) {
  if (priority == 'Urgent') return const Color(0xFFDC2626);
  if (priority == 'High') return const Color(0xFFF43F5E);
  if (priority == 'Medium') return const Color(0xFFF59E0B);
  return const Color(0xFF10B981);
}

DateTime? _taskDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

TimeOfDay? _taskTime(dynamic value) {
  final raw = value?.toString() ?? '';
  final parts = raw.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _taskTimeText(TimeOfDay? time) {
  if (time == null) return 'End of day';
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String _taskDueText(dynamic task) {
  if (task is! Map) return 'No due date';
  final due = _taskDate(task['dueDate'] ?? task['deadline']);
  if (due == null) return 'No due date';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dueDay = DateTime(due.year, due.month, due.day);
  final diff = dueDay.difference(today).inDays;
  final dateText = diff == 0
      ? 'Today'
      : diff == 1
          ? 'Tomorrow'
          : diff == -1
              ? 'Yesterday'
              : '${due.day}/${due.month}/${due.year}';
  return '$dateText · ${_taskTimeText(_taskTime(task['dueTime']))}';
}

bool _taskIsVisuallyOverdue(dynamic task) {
  if (task is! Map) return false;
  if ((task['status'] ?? '').toString() == 'Completed') return false;
  final due = _taskDate(task['dueDate'] ?? task['deadline']);
  if (due == null) return false;
  final time = _taskTime(task['dueTime']);
  final dueAt = DateTime(
    due.year,
    due.month,
    due.day,
    time?.hour ?? 23,
    time?.minute ?? 59,
  );
  return dueAt.isBefore(DateTime.now());
}

String _taskReminderLabel(dynamic task) {
  if (task is! Map || task['notificationEnabled'] != true) return '';
  switch ((task['reminderType'] ?? 'none').toString()) {
    case 'at_time':
      return 'Reminder: due time';
    case '15_min_before':
      return 'Reminder: 15 min';
    case '30_min_before':
      return 'Reminder: 30 min';
    case '1_hour_before':
      return 'Reminder: 1 hour';
    case '1_day_before':
      return 'Reminder: 1 day';
    case 'custom':
      return 'Reminder: custom';
    default:
      return '';
  }
}

class ProjectDetailScreen extends StatelessWidget {
  final Color backgroundColor;
  final Color borderColor;
  final List<Widget> children;

  const ProjectDetailScreen({
    super.key,
    required this.backgroundColor,
    required this.borderColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          border: Border.all(color: borderColor),
        ),
        child: Column(children: children),
      ),
    );
  }
}
