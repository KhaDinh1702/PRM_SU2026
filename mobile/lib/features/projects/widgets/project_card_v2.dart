import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../services/theme_service.dart';
import '../models/project_model.dart';
import 'project_shared.dart';

/// Unified project card.
///
/// Always renders the same information: title, state pill, optional attention
/// badge, members + type meta, progress bar and meta footer (tasks · deadline).
/// The deprecated `compact` flag is kept as a no-op signature on existing
/// callers but does not change layout — only horizontal padding tightens.
class ProjectCardV2 extends StatelessWidget {
  final ProjectModel project;
  final bool compact;
  final VoidCallback onTap;

  const ProjectCardV2({
    super.key,
    required this.project,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final accent = project.accentColor;
    final showAttention = project.needsAttention;
    final padding = compact ? 12.0 : 16.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusM),
      child: GlassCard(
        borderRadius: AppSizes.radiusM,
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AccentBar(color: accent),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TitleRow(
                        title: project.name,
                        stateLabel: project.stateLabel,
                        stateColor: accent,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 4),
                      _MetaRow(
                        memberCount: project.memberCount,
                        type: project.type,
                        captionColor: captionColor,
                      ),
                      if (showAttention) ...[
                        const SizedBox(height: 8),
                        _AttentionBadge(reason: project.attentionReason),
                      ],
                      const SizedBox(height: 12),
                      _ProgressBlock(
                        progress: project.progress,
                        accent: accent,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _FooterRow(
                        completed: project.completedTasks,
                        total: project.totalTasks,
                        deadline: project.deadline,
                        accent: accent,
                        captionColor: captionColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentBar extends StatelessWidget {
  final Color color;
  const _AccentBar({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(AppSizes.radiusM),
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final String title;
  final String stateLabel;
  final Color stateColor;
  final Color textColor;

  const _TitleRow({
    required this.title,
    required this.stateLabel,
    required this.stateColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ProjectStatusPill(label: stateLabel, color: stateColor),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  final int memberCount;
  final String type;
  final Color captionColor;

  const _MetaRow({
    required this.memberCount,
    required this.type,
    required this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    final memberLabel = '$memberCount ${memberCount == 1 ? 'member' : 'members'}';
    return Text(
      '$memberLabel · $type',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: captionColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _AttentionBadge extends StatelessWidget {
  static const Color color = Color(0xFFEF4444);
  final String reason;

  const _AttentionBadge({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSizes.radiusRound),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            reason,
            style: const TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBlock extends StatelessWidget {
  final int progress;
  final Color accent;
  final bool isDark;

  const _ProgressBlock({
    required this.progress,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 44,
          child: Text(
            '$progress%',
            style: TextStyle(
              color: accent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 6,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterRow extends StatelessWidget {
  final int completed;
  final int total;
  final DateTime? deadline;
  final Color accent;
  final Color captionColor;

  const _FooterRow({
    required this.completed,
    required this.total,
    required this.deadline,
    required this.accent,
    required this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    final taskText = total == 0 ? 'No tasks' : '$completed/$total tasks';
    final deadlineText =
        deadline == null ? 'No deadline' : DateFormat('MMM d').format(deadline!);
    final deadlineColor = deadline == null ? captionColor : accent;

    return Row(
      children: [
        Icon(Icons.check_circle_outline_rounded,
            size: 14, color: captionColor),
        const SizedBox(width: 4),
        Text(
          taskText,
          style: TextStyle(
            color: captionColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Icon(Icons.event_rounded, size: 14, color: deadlineColor),
        const SizedBox(width: 4),
        Text(
          deadlineText,
          style: TextStyle(
            color: deadlineColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
