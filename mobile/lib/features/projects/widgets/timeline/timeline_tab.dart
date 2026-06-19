import 'package:flutter/material.dart';

import '../../../../services/theme_service.dart';
import '../../models/project_milestone.dart';
import '../project_shared.dart';
import 'timeline_milestone_card.dart';

class ProjectTimelineTab extends StatefulWidget {
  final List<ProjectMilestone> milestones;
  final bool isLoading;

  const ProjectTimelineTab({
    super.key,
    required this.milestones,
    this.isLoading = false,
  });

  @override
  State<ProjectTimelineTab> createState() => _ProjectTimelineTabState();
}

class _ProjectTimelineTabState extends State<ProjectTimelineTab> {
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.milestones.isNotEmpty) {
      _expandedIds.add(widget.milestones.first.id);
    }
  }

  @override
  void didUpdateWidget(covariant ProjectTimelineTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_expandedIds.isEmpty && widget.milestones.isNotEmpty) {
      _expandedIds.add(widget.milestones.first.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Text(
          'Project Timeline',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Track milestones from kickoff to deployment.',
          style: TextStyle(color: captionColor, fontSize: 12),
        ),
        const SizedBox(height: 16),
        if (widget.milestones.isEmpty)
          ProjectEmptyState(
            icon: Icons.timeline_rounded,
            title: 'No milestones yet',
            text: 'Create a milestone from the + button.',
            cta: null,
            onPressed: () {},
          )
        else
          ...widget.milestones.asMap().entries.map((entry) {
            final index = entry.key;
            final milestone = entry.value;
            return TimelineMilestoneCard(
              milestone: milestone,
              isFirst: index == 0,
              isLast: index == widget.milestones.length - 1,
              isExpanded: _expandedIds.contains(milestone.id),
              onToggle: () => setState(() {
                if (_expandedIds.contains(milestone.id)) {
                  _expandedIds.remove(milestone.id);
                } else {
                  _expandedIds.add(milestone.id);
                }
              }),
            );
          }),
      ],
    );
  }
}
