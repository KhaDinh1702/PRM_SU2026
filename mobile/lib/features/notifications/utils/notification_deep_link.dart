import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../calendar/screens/calendar_screen.dart';
import '../../projects/screens/project_screen.dart';
import '../../tasks/screens/task_screen.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../screens/notifications_screen.dart';

/// Routes a notification tap to the most relevant destination based on its
/// type. Also marks the notification as read so the bell badge updates.
///
/// Fallback: if the type doesn't have a dedicated screen (or the related id
/// is missing), we push the full notifications inbox so the user still sees
/// what they tapped.
class NotificationDeepLink {
  const NotificationDeepLink._();

  static Future<void> open(
    BuildContext context,
    NotificationModel notification,
  ) async {
    // Mark as read first (optimistic — fire and forget).
    if (!notification.isRead) {
      context.read<NotificationProvider>().markAsRead(notification.id);
    }

    final target = _targetFor(notification);
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => target));
  }

  static Widget _targetFor(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.invitation:
      case NotificationType.project:
        return const ProjectScreen();
      case NotificationType.task:
        return const TaskScreen();
      case NotificationType.meeting:
        return const CalendarScreen();
      case NotificationType.system:
        return const NotificationsScreen();
    }
  }
}
