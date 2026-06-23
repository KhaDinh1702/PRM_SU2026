import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/focus_session.dart';

/// One row in the focus history list. Shows what the session was for,
/// how long it ran, whether it completed naturally, and the time of day
/// it took place. Cancelled sessions get a muted look so the user can
/// still see the effort but understand it wasn't a full block.
class FocusSessionCard extends StatelessWidget {
  final FocusSession session;

  static const Color _focusAccent = Color(0xFF06B6D4);
  static const Color _breakAccent = Color(0xFF10B981);
  static const Color _cancelledAccent = Color(0xFFEF4444);

  const FocusSessionCard({super.key, required this.session});

  Color get _accent {
    if (!session.completed) return _cancelledAccent;
    return session.mode.isBreak ? _breakAccent : _focusAccent;
  }

  IconData get _icon {
    if (!session.completed) return Icons.cancel_outlined;
    return session.mode.isBreak
        ? Icons.coffee_rounded
        : Icons.center_focus_strong_rounded;
  }

  String _modeLabel() {
    if (!session.completed) {
      return LocaleService.tr('Đã huỷ', en: 'Cancelled');
    }
    switch (session.mode) {
      case FocusSessionMode.focus:
        return LocaleService.tr('Tập trung', en: 'Focus');
      case FocusSessionMode.shortBreak:
        return LocaleService.tr('Nghỉ ngắn', en: 'Short break');
      case FocusSessionMode.longBreak:
        return LocaleService.tr('Nghỉ dài', en: 'Long break');
      case FocusSessionMode.custom:
        return LocaleService.tr('Tuỳ chỉnh', en: 'Custom');
    }
  }

  String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDuration(int seconds) {
    final mins = (seconds / 60).round();
    if (mins < 1) return '< 1m';
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    final title = session.taskTitle ??
        LocaleService.tr('Không gắn task', en: 'No task linked');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _accent.withValues(alpha: 0.32)),
            ),
            child: Icon(_icon, size: 18, color: _accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_modeLabel()} · ${_formatClock(session.startedAt)}',
                  style: TextStyle(
                    color: captionColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(session.durationSeconds),
            style: TextStyle(
              color: _accent,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
