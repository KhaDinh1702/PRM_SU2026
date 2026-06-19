import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../providers/kanban_provider.dart';
import '../../utils/project_board_utils.dart';

/// Centralised colour palette for the mobile Kanban board.
///
/// Priority colours follow the Kanban spec (Low = Blue, Medium = Orange,
/// High = Red) and are intentionally decoupled from [AppColors.priorityColor],
/// which the rest of the app uses for its own task list.
class BoardPalette {
  BoardPalette._();

  static const Color low = Color(0xFF2563EB); // Blue
  static const Color medium = Color(0xFFF59E0B); // Orange
  static const Color high = Color(0xFFEF4444); // Red

  static const Color neutral = Color(0xFF64748B);
  static const Color assignee = Color(0xFF8B5CF6);
  static const Color sort = Color(0xFF06B6D4);

  /// Spec-aligned priority colour for a raw priority string. `Urgent`
  /// collapses into [high] so the existing backend vocabulary keeps working.
  static Color priorityColorFromString(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
      case 'high':
        return high;
      case 'medium':
        return medium;
      case 'low':
        return low;
      default:
        return neutral;
    }
  }

  static Color priorityColor(KanbanPriority priority) {
    switch (priority) {
      case KanbanPriority.low:
        return low;
      case KanbanPriority.medium:
        return medium;
      case KanbanPriority.high:
        return high;
    }
  }

  /// Accent colour rendered on the left edge of each task card to communicate
  /// its column. Mirrors the dot colour shown in the section header.
  static Color statusColor(BoardColumn column) {
    switch (column) {
      case BoardColumn.todo:
        return Colors.blueGrey;
      case BoardColumn.inProgress:
        return AppColors.taskAccent;
      case BoardColumn.review:
        return const Color(0xFFF59E0B);
      case BoardColumn.completed:
        return AppColors.success;
    }
  }
}
