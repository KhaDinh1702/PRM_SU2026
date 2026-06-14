import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Enum trạng thái task
enum TaskStatus { pending, inProgress, completed }

/// Enum mức độ ưu tiên task
enum TaskPriority { low, medium, high, urgent }

/// Enum nguồn gốc task
enum TaskSource { personal, project, schedule }

/// Model đại diện cho một Task — thay thế cho Map<String, dynamic>
class TaskModel {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final TaskSource source;
  final DateTime? deadline;
  final DateTime? dueDate;
  final String? dueTime;
  final bool notificationEnabled;
  final String? reminderType;
  final Map<String, dynamic>? project;
  final Map<String, dynamic>? assignedTo;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.source,
    this.deadline,
    this.dueDate,
    this.dueTime,
    this.notificationEnabled = false,
    this.reminderType,
    this.project,
    this.assignedTo,
  });

  /// Parse từ JSON response của backend
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: _parseStatus(json['status']?.toString()),
      priority: _parsePriority(json['priority']?.toString()),
      source: _parseSource(json),
      deadline: _parseDate(json['deadline']),
      dueDate: _parseDate(json['dueDate']),
      dueTime: json['dueTime']?.toString(),
      notificationEnabled: json['notificationEnabled'] == true,
      reminderType: json['reminderType']?.toString(),
      project: json['project'] is Map<String, dynamic>
          ? json['project'] as Map<String, dynamic>
          : null,
      assignedTo: json['assignedTo'] is Map<String, dynamic>
          ? json['assignedTo'] as Map<String, dynamic>
          : null,
    );
  }

  /// Trả về DateTime kết hợp deadline + dueTime (nếu có)
  DateTime? get effectiveDueDateTime {
    final base = deadline ?? dueDate;
    if (base == null) return null;
    final timeParts = dueTime?.split(':');
    if (timeParts != null && timeParts.length >= 2) {
      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour != null && minute != null) {
        return DateTime(base.year, base.month, base.day, hour, minute);
      }
    }
    return base;
  }

  /// Kiểm tra xem task có quá hạn không
  bool get isOverdue {
    final due = effectiveDueDateTime;
    return due != null &&
        due.isBefore(DateTime.now()) &&
        status != TaskStatus.completed;
  }

  /// Tên hiển thị của project (nếu có)
  String get projectName {
    if (project == null) return '';
    return project!['name']?.toString() ?? '';
  }

  /// Tên người được giao (nếu có)
  String get assigneeName {
    if (assignedTo == null) return '';
    final name = assignedTo!['name']?.toString();
    if (name != null && name.isNotEmpty) return name;
    return assignedTo!['email']?.toString() ?? '';
  }

  /// Màu theo priority
  Color get priorityColor => AppColors.priorityColor(priority.name);

  /// Màu theo source
  Color get sourceColor {
    switch (source) {
      case TaskSource.project:
        return AppColors.taskAccent;
      case TaskSource.schedule:
        return const Color(0xFF8B5CF6);
      case TaskSource.personal:
        return AppColors.success;
    }
  }

  /// Label hiển thị source
  String get sourceLabel {
    switch (source) {
      case TaskSource.project:
        return 'Project';
      case TaskSource.schedule:
        return 'Schedule';
      case TaskSource.personal:
        return 'Personal';
    }
  }

  // --- Private helpers ---

  static TaskStatus _parseStatus(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'completed':
        return TaskStatus.completed;
      case 'in progress':
        return TaskStatus.inProgress;
      default:
        return TaskStatus.pending;
    }
  }

  static TaskPriority _parsePriority(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'urgent':
        return TaskPriority.urgent;
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      default:
        return TaskPriority.low;
    }
  }

  static TaskSource _parseSource(Map<String, dynamic> json) {
    final sourceType = json['sourceType']?.toString();
    if (sourceType == 'project' || json['project'] != null) {
      return TaskSource.project;
    }
    if (sourceType == 'schedule' || json['scheduleId'] != null) {
      return TaskSource.schedule;
    }
    return TaskSource.personal;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
