import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../../calendar/models/calendar_item.dart';
import '../../calendar/screens/calendar_screen.dart';
import '../../calendar/services/calendar_service.dart';

/// Preview card for today's calendar items, shown in the Profile screen's
/// INSIGHTS section. Loads its own data on mount and exposes a public
/// [reload] hook so the parent's pull-to-refresh can fan out to it.
class CalendarPreviewCard extends StatefulWidget {
  final CalendarService service;

  const CalendarPreviewCard({
    super.key,
    this.service = const CalendarService(),
  });

  @override
  State<CalendarPreviewCard> createState() => CalendarPreviewCardState();
}

class CalendarPreviewCardState extends State<CalendarPreviewCard> {
  bool _loading = true;
  String? _error;
  List<CalendarItem> _items = const [];

  static const int _maxItems = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> reload() => _load();

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));
      final items =
          await widget.service.fetchCalendarItems(start: start, end: end);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openCalendar() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CalendarScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final cardBg = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    const accent = Color(0xFF10B981);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _openCalendar,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(accent: accent, onOpen: _openCalendar),
              const SizedBox(height: 10),
              _Body(
                loading: _loading,
                error: _error,
                items: _items,
                maxItems: _maxItems,
                accent: accent,
                onOpen: _openCalendar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Color accent;
  final VoidCallback onOpen;

  const _Header({required this.accent, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.calendar_month_rounded, color: accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleService.tr('Lịch', en: 'Calendar'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                LocaleService.tr('Hôm nay', en: 'Today'),
                style: TextStyle(color: captionColor, fontSize: 11),
              ),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: captionColor, size: 20),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<CalendarItem> items;
  final int maxItems;
  final Color accent;
  final VoidCallback onOpen;

  const _Body({
    required this.loading,
    required this.error,
    required this.items,
    required this.maxItems,
    required this.accent,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) return const _SkeletonRows();
    if (error != null) {
      return _Message(
        text: LocaleService.tr(
          'Không tải được lịch hôm nay.',
          en: 'Could not load today\'s schedule.',
        ),
        muted: true,
      );
    }
    if (items.isEmpty) {
      return _Message(
        text: LocaleService.tr(
          'Không có sự kiện hôm nay — tận hưởng tập trung 🎯',
          en: 'No events today — enjoy the focus 🎯',
        ),
        muted: false,
      );
    }

    final visible = items.take(maxItems).toList();
    final overflow = items.length - visible.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in visible)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _Row(item: item),
          ),
        if (overflow > 0)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 2),
            child: Text(
              LocaleService.tr(
                '+ $overflow sự kiện khác',
                en: '+$overflow more',
              ),
              style: TextStyle(
                color: accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final CalendarItem item;

  const _Row({required this.item});

  String _timeLabel() {
    if (item.isAllDay) return 'All day';
    final h = item.start.hour.toString().padLeft(2, '0');
    final m = item.start.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: item.accentColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 52,
          child: Text(
            _timeLabel(),
            style: TextStyle(
              color: captionColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  final bool muted;

  const _Message({required this.text, required this.muted});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final color = muted
        ? ThemeService.getCaptionColor(isDark)
        : ThemeService.getSubTextColor(isDark);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, height: 1.4),
      ),
    );
  }
}

class _SkeletonRows extends StatelessWidget {
  const _SkeletonRows();

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final shimmer = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.05);
    return Column(
      children: List.generate(2, (_) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(width: 4, height: 22, color: shimmer),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: shimmer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
