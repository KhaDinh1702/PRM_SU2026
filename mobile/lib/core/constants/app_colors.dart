import 'package:flutter/material.dart';

/// Tất cả màu sắc dùng chung trong app — không hardcode màu rải rác ở màn hình.
class AppColors {
  AppColors._();

  // --- Brand / Primary ---
  static const Color primary = Color(0xFF8B5CF6); // Purple (light)
  static const Color primaryDark = Color(0xFFA78BFA); // Purple (dark)

  // --- Accent Colors ---
  static const Color taskAccent = Color(0xFF06B6D4); // Cyan — Tasks
  static const Color timerFocus = Color(0xFF8B5CF6); // Violet — Focus mode
  static const Color timerBreakShort = Color(0xFF10B981); // Emerald — Short break
  static const Color timerBreakLong = Color(0xFF06B6D4); // Cyan — Long break
  static const Color timerCustom = Color(0xFFF43F5E); // Rose — Custom
  static const Color projectAccent = Color(0xFF06B6D4); // Cyan — Projects
  static const Color notifAccent = Color(0xFFF59E0B); // Amber — Notifications
  static const Color dashboardAccent = Color(0xFF8B5CF6); // Violet — Dashboard
  static const Color analyticsAccent = Color(0xFFEC4899); // Pink — Analytics
  static const Color calendarEvent = Color(0xFF10B981); // Emerald
  static const Color calendarTask = Color(0xFF06B6D4); // Cyan
  static const Color calendarProjectTask = Color(0xFF8B5CF6); // Violet
  static const Color calendarDeadline = Color(0xFFEF4444); // Red

  // --- Status Colors ---
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFF43F5E);
  static const Color info = Color(0xFF06B6D4);
  static const Color overdue = Color(0xFFDC2626);

  // --- Priority Colors ---
  static const Color priorityUrgent = Color(0xFFDC2626);
  static const Color priorityHigh = Color(0xFFF43F5E);
  static const Color priorityMedium = Color(0xFFF59E0B);
  static const Color priorityLow = Color(0xFF10B981);

  // --- Notification Type Colors ---
  static const Color notifTask = Color(0xFF10B981);
  static const Color notifMeeting = Color(0xFFF43F5E);
  static const Color notifProject = Color(0xFF06B6D4);
  static const Color notifInvitation = Colors.blue;
  static const Color notifChat = Color(0xFF3B82F6);
  static const Color notifSystem = Color(0xFF8B5CF6);

  // --- GitHub Theme Surface ---
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFF0D1117);
  static const Color cardLight = Color(0xFFF6F8FA);
  static const Color cardDark = Color(0xFF161B22);
  static const Color borderLight = Color(0xFFD0D7DE);
  static const Color borderDark = Color(0xFF30363D);
  static const Color textLight = Color(0xFF24292F);
  static const Color textDark = Color(0xFFC9D1D9);
  static const Color subTextLight = Color(0xFF57606A);
  static const Color subTextDark = Color(0xFF8B949E);
  static const Color captionLight = Color(0xFF8C959F);
  static const Color captionDark = Color(0xFF484F58);

  // --- Button Colors ---
  static const Color buttonGreenLight = Color(0xFF1F883D);
  static const Color buttonGreenDark = Color(0xFF238636);

  /// Lấy màu priority dựa trên chuỗi status
  static Color priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return priorityUrgent;
      case 'high':
        return priorityHigh;
      case 'medium':
        return priorityMedium;
      default:
        return priorityLow;
    }
  }
}
