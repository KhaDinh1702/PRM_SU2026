import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../../calendar/models/calendar_item.dart';
import '../../tasks/models/task_model.dart';
import '../models/today_item.dart';

/// Vertical timeline of today's tasks + events. All-day items render first,
/// then time-blocked items in chronological order.
class DashboardTodayTimeline extends StatelessWidget {
  final List<TodayItem> items;
  final void Function(TaskModel task)? onTapTask;
  final void Function(CalendarItem event)? onTapEvent;

  const DashboardTodayTimeline({
    super.key,
    required this.items,
    this.onTapTask,
    this.onTapEvent,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _EmptyState();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          _Row(
            item: items[i],
            isFirst: i == 0,
            isLast: i == items.length - 1,
            onTap: () => _dispatch(items[i]),
          ),
      ],
    );
  }

  void _dispatch(TodayItem item) {
    switch (item.kind) {
      case TodayItemKind.task:
      case TodayItemKind.deadline:
        final src = item.source;
        if (src is TaskModel) {
          onTapTask?.call(src);
        } else if (src is CalendarItem) {
          onTapEvent?.call(src);
        }
        break;
      case TodayItemKind.event:
        final src = item.source;
        if (src is CalendarItem) onTapEvent?.call(src);
        break;
    }
  }
}

class _Row extends StatelessWidget {
  final TodayItem item;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  const _Row({
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  String _timeLabel() {
    if (item.isAllDay) return LocaleService.tr('Cả ngày', en: 'All day');
    final h = item.time.hour.toString().padLeft(2, '0');
    final m = item.time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  IconData _icon() {
    switch (item.kind) {
      case TodayItemKind.task:
        return item.isCompleted
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded;
      case TodayItemKind.deadline:
        return Icons.flag_rounded;
      case TodayItemKind.event:
        return Icons.event_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final cardBg = ThemeService.getCardColor(isDark);
    final lineColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.12);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Time column ---
          SizedBox(
            width: 56,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _timeLabel(),
                style: TextStyle(
                  color: captionColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          // --- Rail (vertical line + node) ---
          SizedBox(
            width: 22,
            child: Column(
              children: [
                if (!isFirst)
                  Container(width: 2, height: 16, color: lineColor),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.isCompleted
                        ? item.accentColor
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: item.accentColor, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: lineColor)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // --- Card ---
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: item.accentColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                item.accentColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _icon(),
                            size: 16,
                            color: item.accentColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  decoration: item.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              if (item.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: captionColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: captionColor),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final cardBg = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded,
              size: 28, color: subTextColor.withValues(alpha: 0.7)),
          const SizedBox(height: 8),
          Text(
            LocaleService.tr(
              'Hôm nay không có lịch',
              en: 'Nothing scheduled today',
            ),
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            LocaleService.tr(
              'Tận hưởng khoảng trống — hoặc thêm task / sự kiện mới.',
              en: 'Enjoy the breathing room — or add a task or event.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subTextColor,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
