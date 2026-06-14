import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Enum loại thông báo
enum NotificationType { task, meeting, project, invitation, system }

/// Enum trạng thái lời mời
enum InvitationStatus { pending, accepted, rejected }

/// Model đại diện cho một Notification — thay thế Map<String, dynamic>
class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime? createdAt;
  final InvitationStatus? invitationStatus;
  final Map<String, dynamic>? relatedId;
  final Map<String, dynamic>? sender;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.createdAt,
    this.invitationStatus,
    this.relatedId,
    this.sender,
  });

  /// Parse từ JSON response của backend
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      type: _parseType(json['type']?.toString()),
      isRead: json['isRead'] == true,
      createdAt: _parseDate(json['createdAt']),
      invitationStatus: _parseInvitationStatus(
          json['invitationStatus']?.toString()),
      relatedId: json['relatedId'] is Map<String, dynamic>
          ? json['relatedId'] as Map<String, dynamic>
          : null,
      sender: json['sender'] is Map<String, dynamic>
          ? json['sender'] as Map<String, dynamic>
          : null,
    );
  }

  /// Trả về Map với isRead đã cập nhật (dùng khi mark as read)
  NotificationModel copyWithRead() {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      type: type,
      isRead: true,
      createdAt: createdAt,
      invitationStatus: invitationStatus,
      relatedId: relatedId,
      sender: sender,
    );
  }

  /// Kiểm tra có phải lời mời đang chờ không
  bool get isPendingInvitation =>
      type == NotificationType.invitation &&
      invitationStatus == InvitationStatus.pending;

  /// Tên project trong lời mời
  String get invitationProjectName =>
      relatedId?['name']?.toString() ?? 'Unknown Project';

  /// ID project trong lời mời
  String get invitationProjectId =>
      relatedId?['_id']?.toString() ?? '';

  /// Tên người gửi lời mời
  String get senderName {
    if (sender == null) return 'Someone';
    return sender!['name']?.toString().isNotEmpty == true
        ? sender!['name'].toString()
        : sender!['email']?.toString() ?? 'Someone';
  }

  /// Màu theo type
  Color get typeColor {
    switch (type) {
      case NotificationType.task:
        return AppColors.notifTask;
      case NotificationType.meeting:
        return AppColors.notifMeeting;
      case NotificationType.project:
        return AppColors.notifProject;
      case NotificationType.invitation:
        return AppColors.notifInvitation;
      case NotificationType.system:
        return AppColors.notifSystem;
    }
  }

  /// Icon theo type
  IconData get typeIcon {
    switch (type) {
      case NotificationType.task:
        return Icons.task_alt_rounded;
      case NotificationType.meeting:
        return Icons.videocam_rounded;
      case NotificationType.project:
        return Icons.dns_rounded;
      case NotificationType.invitation:
        return Icons.group_add_rounded;
      case NotificationType.system:
        return Icons.notifications_rounded;
    }
  }

  /// Label theo type
  String get typeLabel {
    switch (type) {
      case NotificationType.task:
        return 'Task';
      case NotificationType.meeting:
        return 'Meeting';
      case NotificationType.project:
        return 'Project';
      case NotificationType.invitation:
        return 'Invite';
      case NotificationType.system:
        return 'System';
    }
  }

  // --- Private helpers ---

  static NotificationType _parseType(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'task':
        return NotificationType.task;
      case 'meeting':
        return NotificationType.meeting;
      case 'project':
        return NotificationType.project;
      case 'invitation':
        return NotificationType.invitation;
      default:
        return NotificationType.system;
    }
  }

  static InvitationStatus? _parseInvitationStatus(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'pending':
        return InvitationStatus.pending;
      case 'accepted':
        return InvitationStatus.accepted;
      case 'rejected':
        return InvitationStatus.rejected;
      default:
        return null;
    }
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
