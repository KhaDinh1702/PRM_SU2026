import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/premium_widgets.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../../calendar/models/calendar_item.dart';

class DashboardUpcomingEventsSection extends StatelessWidget {
  final List<CalendarItem> events;

  const DashboardUpcomingEventsSection({
    super.key,
    required this.events,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleService.tr('Sự kiện sắp tới', en: 'Upcoming Events'),
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        if (events.isEmpty)
          GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: Color(0xFF10B981),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    LocaleService.tr(
                      'Không có sự kiện sắp tới.',
                      en: 'No upcoming events.',
                    ),
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          ...events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                borderRadius: 18,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 44,
                      decoration: BoxDecoration(
                        color: event.accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatEventTime(event),
                            style: TextStyle(
                              color: captionColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: captionColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _formatEventTime(CalendarItem event) {
    final locale = LocaleService.languageCode.value;
    final date = DateFormat('EEE, MMM d', locale).format(event.start);
    if (event.isAllDay) return date;
    final time = DateFormat('HH:mm', locale).format(event.start);
    return '$date · $time';
  }
}
