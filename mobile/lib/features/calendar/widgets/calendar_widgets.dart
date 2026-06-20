import 'package:flutter/material.dart';

import '../../../services/theme_service.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../models/calendar_item.dart';
import '../utils/calendar_utils.dart';

/// Top header for the Calendar screen: back button (if pushed), title, and
/// a compact "+ New" CTA. Replaces the previous tall two-line header that
/// got clipped under the status bar.
class CalendarHeader extends StatelessWidget {
  final Color textColor;
  final Color captionColor;
  final VoidCallback onAddPressed;

  const CalendarHeader({
    super.key,
    required this.textColor,
    required this.captionColor,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    const accent = Color(0xFF06B6D4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.arrow_back_rounded, color: textColor),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Calendar',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          FilledButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              'New',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CalendarFilterTabs extends StatelessWidget {
  final CalendarFilter selectedFilter;
  final ValueChanged<CalendarFilter> onChanged;

  const CalendarFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onChanged,
  });

  /// Filter chip metadata. "Overdue" stays as a quick-access state filter
  /// — semantically not a type, but it is the most common follow-up when
  /// browsing dates.
  static const _filters = <(CalendarFilter, String, IconData)>[
    (CalendarFilter.all, 'All', Icons.layers_rounded),
    (CalendarFilter.events, 'Events', Icons.event_rounded),
    (CalendarFilter.tasks, 'Tasks', Icons.checklist_rounded),
    (CalendarFilter.project, 'Projects', Icons.dns_rounded),
    (CalendarFilter.overdue, 'Overdue', Icons.warning_amber_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    const accent = Color(0xFF06B6D4);
    const overdueAccent = Color(0xFFEF4444);

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final entry = _filters[index];
          final filter = entry.$1;
          final label = entry.$2;
          final icon = entry.$3;
          final selected = filter == selectedFilter;
          final accentColor =
              filter == CalendarFilter.overdue ? overdueAccent : accent;

          final fg = selected ? Colors.white : captionColor;
          final bg = selected
              ? accentColor
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04));
          final border = selected
              ? accentColor
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08));

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onChanged(filter),
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: fg),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MonthCalendarCard extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final List<CalendarItem> items;
  final Color textColor;
  final Color captionColor;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelectDate;

  const MonthCalendarCard({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.items,
    required this.textColor,
    required this.captionColor,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final days = visibleCalendarDays(focusedMonth);

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  formatMonthTitle(focusedMonth),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _MonthButton(icon: Icons.chevron_left, onTap: onPrevious),
              const SizedBox(width: 8),
              _MonthButton(icon: Icons.chevron_right, onTap: onNext),
            ],
          ),
          const SizedBox(height: 16),
          WeekdayRow(captionColor: captionColor),
          const SizedBox(height: 8),
          GridView.builder(
            itemCount: days.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.86,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              return DayCell(
                date: day,
                isCurrentMonth: day.month == focusedMonth.month,
                isSelected: isSameDay(day, selectedDate),
                isToday: isSameDay(day, DateTime.now()),
                counts: getDateIndicatorCounts(day, items),
                textColor: textColor,
                captionColor: captionColor,
                onTap: () => onSelectDate(day),
              );
            },
          ),
          const SizedBox(height: 14),
          const CalendarLegend(),
        ],
      ),
    );
  }
}

class WeekdayRow extends StatelessWidget {
  final Color captionColor;

  const WeekdayRow({super.key, required this.captionColor});

  @override
  Widget build(BuildContext context) {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: captionColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class DayCell extends StatelessWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final DateIndicatorCounts counts;
  final Color textColor;
  final Color captionColor;
  final VoidCallback onTap;

  const DayCell({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.counts,
    required this.textColor,
    required this.captionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isCurrentMonth ? textColor : captionColor.withValues(alpha: 0.45);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF06B6D4).withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF06B6D4)
                : isToday
                    ? const Color(0xFF06B6D4).withValues(alpha: 0.42)
                    : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected ? const Color(0xFF06B6D4) : color,
                fontSize: 13,
                fontWeight:
                    isSelected || isToday ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            _DotRow(counts: counts),
          ],
        ),
      ),
    );
  }
}

class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _LegendItem(color: Color(0xFF10B981), label: 'Events'),
        _LegendItem(color: Color(0xFF06B6D4), label: 'Tasks'),
        _LegendItem(color: Color(0xFF8B5CF6), label: 'Project Tasks'),
        _LegendItem(color: Color(0xFFEF4444), label: 'Deadlines'),
      ],
    );
  }
}

class AgendaSection extends StatelessWidget {
  final DateTime selectedDate;
  final List<CalendarItem> items;
  final Color textColor;
  final Color subTextColor;
  final Color captionColor;
  final ValueChanged<CalendarItem> onTapItem;

  const AgendaSection({
    super.key,
    required this.selectedDate,
    required this.items,
    required this.textColor,
    required this.subTextColor,
    required this.captionColor,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = groupCalendarItemsByTime(items);
    final allDay = grouped['All-day'] ?? [];
    final timedEntries = grouped.entries
        .where((entry) => entry.key != 'All-day')
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final countLabel =
        items.length == 1 ? '1 item' : '${items.length} items';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                agendaTitle(selectedDate),
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: captionColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                countLabel,
                style: TextStyle(
                  color: captionColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _CalendarEmptyState(captionColor: captionColor, textColor: textColor)
        else ...[
          if (allDay.isNotEmpty)
            _AgendaGroup(
              label: 'All-day',
              items: allDay,
              textColor: textColor,
              subTextColor: subTextColor,
              onTapItem: onTapItem,
            ),
          for (final entry in timedEntries)
            _AgendaGroup(
              label: entry.key,
              items: entry.value,
              textColor: textColor,
              subTextColor: subTextColor,
              onTapItem: onTapItem,
            ),
        ],
      ],
    );
  }
}

class AgendaItemCard extends StatelessWidget {
  final CalendarItem item;
  final Color textColor;
  final Color subTextColor;
  final VoidCallback onTap;

  const AgendaItemCard({
    super.key,
    required this.item,
    required this.textColor,
    required this.subTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 18,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 58,
              decoration: BoxDecoration(
                color: item.accentColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 12),
            CalendarTypeIcon(item: item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (item.hasReminder)
                        Icon(
                          Icons.notifications_active_rounded,
                          size: 14,
                          color: item.accentColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    agendaItemSecondaryLine(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      CalendarInfoPill(
                        icon: Icons.label_rounded,
                        text: item.typeLabel,
                        color: item.accentColor,
                      ),
                      if (item.status?.isNotEmpty == true)
                        CalendarInfoPill(
                          icon: Icons.flag_rounded,
                          text: item.status!,
                          color: item.accentColor,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: subTextColor.withValues(alpha: 0.65),
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarAddSheetAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const CalendarAddSheetAction({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: subTextColor),
            ],
          ),
        ),
      ),
    );
  }
}

class CalendarDateTimeSelector extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  const CalendarDateTimeSelector({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF06B6D4)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(color: subTextColor, fontSize: 11),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    formatDateTime(value),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: subTextColor),
          ],
        ),
      ),
    );
  }
}

class CalendarRoundedDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  const CalendarRoundedDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: subTextColor.withValues(alpha: 0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: dialogBg,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: subTextColor),
          onChanged: enabled ? onChanged : null,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(color: subTextColor, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        itemLabel(item),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class CalendarTypeIcon extends StatelessWidget {
  final CalendarItem item;
  final double size;

  const CalendarTypeIcon({
    super.key,
    required this.item,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    if (item.isOverdue || item.kind == CalendarItemKind.deadline) {
      icon = Icons.warning_amber_rounded;
    } else if (item.kind == CalendarItemKind.event) {
      icon = Icons.event_rounded;
    } else if (item.kind == CalendarItemKind.projectTask) {
      icon = Icons.folder_rounded;
    } else {
      icon = Icons.task_alt_rounded;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: item.accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Icon(icon, color: item.accentColor, size: size * 0.5),
    );
  }
}

class CalendarInfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const CalendarInfoPill({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class AgendaSkeleton extends StatelessWidget {
  const AgendaSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ShimmerLoading(width: double.infinity, height: 86, borderRadius: 18),
        SizedBox(height: 12),
        ShimmerLoading(width: double.infinity, height: 86, borderRadius: 18),
      ],
    );
  }
}

class _AgendaGroup extends StatelessWidget {
  final String label;
  final List<CalendarItem> items;
  final Color textColor;
  final Color subTextColor;
  final ValueChanged<CalendarItem> onTapItem;

  const _AgendaGroup({
    required this.label,
    required this.items,
    required this.textColor,
    required this.subTextColor,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                color: subTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AgendaItemCard(
                item: item,
                textColor: textColor,
                subTextColor: subTextColor,
                onTap: () => onTapItem(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotRow extends StatelessWidget {
  final DateIndicatorCounts counts;

  const _DotRow({required this.counts});

  @override
  Widget build(BuildContext context) {
    if (!counts.hasAny) return const SizedBox(height: 5);
    final dots = <Color>[
      if (counts.events > 0) const Color(0xFF10B981),
      if (counts.personalTasks > 0) const Color(0xFF06B6D4),
      if (counts.projectTasks > 0) const Color(0xFF8B5CF6),
      if (counts.deadlines > 0) const Color(0xFFEF4444),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: dots
          .take(4)
          .map(
            (color) => Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          )
          .toList(),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final subTextColor = ThemeService.getSubTextColor(isDark);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: subTextColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MonthButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: const Color(0xFF06B6D4)),
      ),
    );
  }
}

class _CalendarEmptyState extends StatelessWidget {
  final Color captionColor;
  final Color textColor;

  const _CalendarEmptyState({
    required this.captionColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 44,
              color: captionColor.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 12),
            Text(
              'No events or tasks for this day',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your scheduled events and tasks with deadlines will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: captionColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
