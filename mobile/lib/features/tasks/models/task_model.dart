import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Enum trạng thái task
enum TaskStatus { pending, inProgress, review, completed }

/// Enum mức độ ưu tiên task
enum TaskPriority { low, medium, high, urgent }

/// Enum nguồn gốc task
enum TaskSource { personal, project, schedule }

class TaskLocation {
  final String placeName;
  final String address;
  final double latitude;
  final double longitude;
  final int reminderRadiusMeters;

  const TaskLocation({
    required this.placeName,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.reminderRadiusMeters = 100,
  });

  factory TaskLocation.fromJson(Map<String, dynamic> json) {
    return TaskLocation(
      placeName: json['placeName']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      reminderRadiusMeters:
          int.tryParse(json['reminderRadiusMeters']?.toString() ?? '') ?? 100,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeName': placeName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'reminderRadiusMeters': reminderRadiusMeters,
    };
  }

  bool get isValid => latitude != 0 && longitude != 0;

  String get displayName {
    if (placeName.trim().isNotEmpty) return placeName.trim();
    if (address.trim().isNotEmpty) return address.trim();
    return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
  }

  static double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

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
  final TaskLocation? location;

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
    this.location,
  });

  /// Parse từ JSON response của backend
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    // Project tasks historically arrive with the assignee under either
    // `assignedTo` (new endpoint) or `user` (older endpoint). Accept both
    // so consumers can stop checking themselves.
    final rawAssignee = json['assignedTo'] ?? json['user'];
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
      project: json['project'] is Map
          ? Map<String, dynamic>.from(json['project'] as Map)
          : null,
      assignedTo:
          rawAssignee is Map ? Map<String, dynamic>.from(rawAssignee) : null,
      location: json['location'] is Map
          ? TaskLocation.fromJson(Map<String, dynamic>.from(json['location']))
          : null,
    );
  }

  /// Round-trip back to the legacy `Map<String, dynamic>` shape so
  /// widgets that still consume raw maps can keep working while we migrate.
  /// Once every callsite consumes [TaskModel] directly this can be removed.
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'status': statusLabel,
      'priority': priorityLabel,
      if (deadline != null) 'deadline': deadline!.toIso8601String(),
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      if (dueTime != null) 'dueTime': dueTime,
      'notificationEnabled': notificationEnabled,
      if (reminderType != null) 'reminderType': reminderType,
      if (project != null) 'project': project,
      if (assignedTo != null) 'assignedTo': assignedTo,
      if (location != null) 'location': location!.toJson(),
    };
  }

  /// Tạo bản sao với một vài field được thay đổi
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    TaskSource? source,
    DateTime? deadline,
    DateTime? dueDate,
    String? dueTime,
    bool? notificationEnabled,
    String? reminderType,
    Map<String, dynamic>? project,
    Map<String, dynamic>? assignedTo,
    TaskLocation? location,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      source: source ?? this.source,
      deadline: deadline ?? this.deadline,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      reminderType: reminderType ?? this.reminderType,
      project: project ?? this.project,
      assignedTo: assignedTo ?? this.assignedTo,
      location: location ?? this.location,
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

  /// Chuỗi hiển thị deadline dạng thân thiện
  String get dueText {
    final due = effectiveDueDateTime;
    if (due == null) return 'No due date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final days = dueDay.difference(today).inDays;
    final time =
        '${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}';

    if (days == 0) return 'Due today · $time';
    if (days == 1) return 'Tomorrow · $time';
    if (days == -1) return 'Yesterday · $time';
    if (days < -1) return '${days.abs()} days overdue';
    return '${due.day}/${due.month}/${due.year} · $time';
  }

  /// Nhãn hiển thị chế độ nhắc nhở
  String get reminderLabel {
    if (!notificationEnabled) return '';
    switch (reminderType) {
      case 'at_time':
        return 'Reminder: due time';
      case '15_min_before':
        return 'Reminder: 15 min before';
      case '30_min_before':
        return 'Reminder: 30 min before';
      case '1_hour_before':
        return 'Reminder: 1 hour before';
      case '1_day_before':
        return 'Reminder: 1 day before';
      case 'custom':
        return 'Reminder: custom';
      default:
        return '';
    }
  }

  /// Label hiển thị status
  String get statusLabel {
    switch (status) {
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.review:
        return 'Review';
      case TaskStatus.pending:
        return 'Pending';
    }
  }

  /// Label hiển thị priority
  String get priorityLabel {
    switch (priority) {
      case TaskPriority.urgent:
        return 'Urgent';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
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
  bool get hasLocation => location?.isValid == true;

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
      case 'review':
        return TaskStatus.review;
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
