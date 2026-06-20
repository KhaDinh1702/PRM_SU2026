import 'package:flutter/material.dart';

/// Origin of a milestone.
///
/// - [system] is generated from project metadata (created date, deadline).
///   These cannot be edited or deleted — the UI greys them out.
/// - [user] is created and owned by the project members through the
///   "Create milestone" sheet.
enum MilestoneKind { system, user }

/// Visual / semantic status of a milestone, derived from completion flag and
/// the relationship between today and [ProjectMilestone.targetDate].
enum MilestoneStatus { completed, overdue, dueSoon, inProgress, upcoming }

extension MilestoneStatusX on MilestoneStatus {
  String get label {
    switch (this) {
      case MilestoneStatus.completed:
        return 'Completed';
      case MilestoneStatus.overdue:
        return 'Overdue';
      case MilestoneStatus.dueSoon:
        return 'Due Soon';
      case MilestoneStatus.inProgress:
        return 'In Progress';
      case MilestoneStatus.upcoming:
        return 'Upcoming';
    }
  }

  Color get color {
    switch (this) {
      case MilestoneStatus.completed:
        return const Color(0xFF10B981);
      case MilestoneStatus.overdue:
        return const Color(0xFFEF4444);
      case MilestoneStatus.dueSoon:
        return const Color(0xFFF59E0B);
      case MilestoneStatus.inProgress:
        return const Color(0xFFEAB308);
      case MilestoneStatus.upcoming:
        return const Color(0xFF06B6D4);
    }
  }
}

class ProjectMilestone {
  static const String systemCreatedId = 'system:created';
  static const String systemDeadlineId = 'system:deadline';

  final String id;
  final String title;
  final String? description;
  final DateTime? targetDate;
  final bool isCompleted;
  final MilestoneKind kind;

  const ProjectMilestone({
    required this.id,
    required this.title,
    this.description,
    this.targetDate,
    this.isCompleted = false,
    this.kind = MilestoneKind.user,
  });

  /// Status derived from completion + target date relative to today.
  /// `dueSoon` triggers when targetDate is within the next 3 days.
  MilestoneStatus get status {
    if (isCompleted) return MilestoneStatus.completed;
    final target = targetDate;
    if (target == null) return MilestoneStatus.upcoming;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(target.year, target.month, target.day);
    final diff = due.difference(today).inDays;

    if (diff < 0) return MilestoneStatus.overdue;
    if (diff <= 3) return MilestoneStatus.dueSoon;
    if (diff <= 14) return MilestoneStatus.inProgress;
    return MilestoneStatus.upcoming;
  }

  /// Short human countdown ("Due in 3d", "5d overdue", "Today", "").
  String get countdownLabel {
    final target = targetDate;
    if (target == null || isCompleted) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(target.year, target.month, target.day);
    final diff = due.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff > 0) return 'Due in ${diff}d';
    return '${diff.abs()}d overdue';
  }

  bool get isEditable => kind == MilestoneKind.user;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'targetDate': targetDate?.toIso8601String(),
        'isCompleted': isCompleted,
        'kind': kind.name,
      };

  factory ProjectMilestone.fromJson(Map<String, dynamic> json) {
    return ProjectMilestone(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Milestone',
      description: json['description']?.toString(),
      targetDate: json['targetDate'] != null
          ? DateTime.tryParse(json['targetDate'].toString())?.toLocal()
          : null,
      isCompleted: json['isCompleted'] == true,
      kind: _parseKind(json['kind']),
    );
  }

  ProjectMilestone copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? targetDate,
    bool clearTargetDate = false,
    bool? isCompleted,
    MilestoneKind? kind,
  }) {
    return ProjectMilestone(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate:
          clearTargetDate ? null : (targetDate ?? this.targetDate),
      isCompleted: isCompleted ?? this.isCompleted,
      kind: kind ?? this.kind,
    );
  }

  static MilestoneKind _parseKind(dynamic raw) {
    switch (raw?.toString()) {
      case 'system':
        return MilestoneKind.system;
      default:
        return MilestoneKind.user;
    }
  }
}
