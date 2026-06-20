import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/premium_widgets.dart';
import '../../../../services/theme_service.dart';
import '../../models/project_milestone.dart';
import 'timeline_milestone_card.dart';
import 'timeline_progress_overview.dart';

/// Timeline tab body. Owns only the per-row expand state; all CRUD goes
/// through the callbacks supplied by the parent screen.
class ProjectTimelineTab extends StatefulWidget {
  final List<ProjectMilestone> milestones;
  final bool isLoading;
  final VoidCallback? onCreateMilestone;
  final void Function(ProjectMilestone milestone)? onEditMilestone;
  final void Function(ProjectMilestone milestone)? onDeleteMilestone;
  final void Function(ProjectMilestone milestone)? onToggleComplete;

  const ProjectTimelineTab({
    super.key,
    required this.milestones,
    this.isLoading = false,
    this.onCreateMilestone,
    this.onEditMilestone,
    this.onDeleteMilestone,
    this.onToggleComplete,
  });

  @override
  State<ProjectTimelineTab> createState() => _ProjectTimelineTabState();
}

class _ProjectTimelineTabState extends State<ProjectTimelineTab> {
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _ensureDefaultExpansion();
  }

  @override
  void didUpdateWidget(covariant ProjectTimelineTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ensureDefaultExpansion();
  }

  /// On first render, expand the most recent in-progress user milestone so
  /// the user sees something useful without tapping.
  void _ensureDefaultExpansion() {
    if (_expandedIds.isNotEmpty) return;
    final user = widget.milestones.where((m) => m.isEditable).toList();
    if (user.isNotEmpty) {
      _expandedIds.add(user.first.id);
    }
  }

  void _toggle(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildSkeleton();
    }

    // Body assumes at least the "Project Created" system marker exists; show
    // the empty state only when the service returned literally nothing.
    final showEmpty = widget.milestones.isEmpty ||
        widget.milestones.where((m) => m.isEditable).isEmpty;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        TimelineProgressOverview(milestones: widget.milestones),
        if (showEmpty)
          _EmptyState(onCreate: widget.onCreateMilestone)
        else
          ..._buildMilestoneRows(),
      ],
    );
  }

  List<Widget> _buildMilestoneRows() {
    return widget.milestones.asMap().entries.map((entry) {
      final index = entry.key;
      final milestone = entry.value;
      final isEditable = milestone.isEditable;
      return TimelineMilestoneCard(
        milestone: milestone,
        isFirst: index == 0,
        isLast: index == widget.milestones.length - 1,
        isExpanded: _expandedIds.contains(milestone.id),
        onToggleExpand: () => _toggle(milestone.id),
        onEdit: isEditable
            ? () => widget.onEditMilestone?.call(milestone)
            : null,
        onDelete: isEditable
            ? () => widget.onDeleteMilestone?.call(milestone)
            : null,
        onToggleComplete: isEditable
            ? () => widget.onToggleComplete?.call(milestone)
            : null,
      );
    }).toList();
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: 4,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: ShimmerLoading(
          width: double.infinity,
          height: 76,
          borderRadius: AppSizes.radiusM,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback? onCreate;

  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📍', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              'No milestones yet',
              style: TextStyle(
                color: textColor,
                fontSize: AppSizes.fontL,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Break this project into checkpoints so the team can track real progress.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: captionColor,
                  fontSize: AppSizes.fontS + 1,
                  height: 1.4,
                ),
              ),
            ),
            if (onCreate != null) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add first milestone'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
