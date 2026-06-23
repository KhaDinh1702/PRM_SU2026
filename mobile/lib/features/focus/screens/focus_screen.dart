import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_scaffold_background.dart';
import '../../../core/widgets/notification_bell.dart';
import '../../../services/auth_service.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/focus_session.dart';
import '../providers/focus_provider.dart';
import '../widgets/focus_active_card.dart';
import '../widgets/focus_duration_picker.dart';
import '../widgets/focus_session_card.dart';
import '../widgets/focus_stats_grid.dart';
import '../widgets/focus_task_picker_sheet.dart';
import '../widgets/focus_week_chart.dart';

/// Top-level screen for the Focus / Pomodoro flow. Owns the 1-second
/// tick driver and translates UI actions into [FocusProvider] calls.
class FocusScreen extends StatefulWidget {
  /// Optional task to pre-select when the screen is opened from a task
  /// detail sheet — supplies both id and title.
  final String? initialTaskId;
  final String? initialTaskTitle;

  const FocusScreen({super.key, this.initialTaskId, this.initialTaskTitle});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen>
    with WidgetsBindingObserver {
  Timer? _ticker;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    // Auto-pause when the user leaves the app so we don't credit time
    // the user wasn't actually focusing. They explicitly hit Resume when
    // they come back.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final provider = context.read<FocusProvider>();
      if (provider.isRunning) {
        provider.pause();
      }
    }
  }

  Future<void> _bootstrap() async {
    final userInfo = await AuthService.getUserInfo();
    final userId =
        (userInfo?['_id'] ?? userInfo?['id'] ?? '').toString();
    if (!mounted) return;
    final provider = context.read<FocusProvider>();
    await provider.bind(userId: userId);
    if (!mounted) return;
    if (widget.initialTaskId != null && widget.initialTaskId!.isNotEmpty) {
      provider.selectTask(
        id: widget.initialTaskId!,
        title: widget.initialTaskTitle ?? '',
      );
    }
    _ensureTicker(provider);
  }

  /// Toggle the periodic ticker on/off based on whether anything is
  /// actually counting down. Keeps the device idle when the screen sits
  /// at rest. When [provider.tick] reports a natural completion we
  /// surface a snackbar + haptic so the user knows even if their eyes
  /// were off the timer.
  void _ensureTicker(FocusProvider provider) {
    if (provider.isRunning) {
      _ticker ??= Timer.periodic(
        const Duration(seconds: 1),
        (_) => _onTick(provider),
      );
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Future<void> _onTick(FocusProvider provider) async {
    final completed = await provider.tick();
    if (!completed || !mounted) return;
    HapticFeedback.mediumImpact();
    // Pull the just-finished session so we can describe it in the toast.
    final last = provider.history.isNotEmpty ? provider.history.first : null;
    final minutes = last?.minutes ?? 0;
    final wasFocus =
        last != null && !last.mode.isBreak && last.completed;
    final message = wasFocus
        ? LocaleService.tr(
            'Hoàn thành $minutes phút focus! 🎯',
            en: 'Completed $minutes min of focus! 🎯',
          )
        : LocaleService.tr(
            'Hết giờ nghỉ — sẵn sàng phiên mới',
            en: 'Break finished — ready for the next round',
          );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF06B6D4),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _onPickTask() async {
    final picked = await FocusTaskPickerSheet.show(context);
    if (picked == null || !mounted) return;
    final provider = context.read<FocusProvider>();
    if (picked.id == null) {
      provider.clearTask();
    } else {
      provider.selectTask(id: picked.id!, title: picked.title ?? '');
    }
  }

  Future<void> _onEditDuration() async {
    final provider = context.read<FocusProvider>();
    // Refuse to edit mid-session — the chip is already disabled but this
    // also covers the timer-tap path.
    if (provider.hasActiveSession) return;
    final currentMinutes = (provider.totalSeconds / 60).round();
    final picked = await FocusDurationPickerSheet.show(
      context,
      initialMinutes: currentMinutes,
    );
    if (picked == null || !mounted) return;
    provider.setMode(FocusSessionMode.custom, customMinutes: picked);
  }

  Future<void> _confirmCancel(FocusProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleService.tr('Huỷ phiên?', en: 'Cancel session?')),
        content: Text(
          LocaleService.tr(
            'Phiên đang chạy sẽ được lưu vào lịch sử với trạng thái "đã huỷ". Tiếp tục?',
            en:
                'The current session will be saved as cancelled in history. Continue?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocaleService.tr('Không', en: 'No')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(LocaleService.tr('Huỷ phiên', en: 'Cancel')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await provider.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffoldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: Listenable.merge(
                [ThemeService.isDarkMode, LocaleService.languageCode]),
            builder: (context, _) {
              return Consumer<FocusProvider>(
                builder: (context, provider, _) {
                  _ensureTicker(provider);
                  return _buildContent(provider);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(FocusProvider provider) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return RefreshIndicator(
      onRefresh: provider.reloadHistory,
      color: const Color(0xFF06B6D4),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          _Header(textColor: textColor, captionColor: captionColor),
          const SizedBox(height: 16),
          FocusActiveCard(
            provider: provider,
            onPickTask: _onPickTask,
            onEditDuration: _onEditDuration,
            onStart: provider.start,
            onPause: provider.pause,
            onResume: provider.resume,
            onCancel: () => _confirmCancel(provider),
            onSkipBreak: provider.skipBreak,
          ),
          const SizedBox(height: 18),
          FocusStatsGrid(stats: provider.stats),
          const SizedBox(height: 14),
          _SectionTabs(
            index: _tabIndex,
            onChanged: (i) => setState(() => _tabIndex = i),
          ),
          const SizedBox(height: 12),
          if (_tabIndex == 0) _TodayList(provider: provider),
          if (_tabIndex == 1) _StatsTab(provider: provider),
          if (_tabIndex == 2) _HistoryTab(provider: provider),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Color textColor;
  final Color captionColor;

  const _Header({required this.textColor, required this.captionColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleService.tr('NĂNG SUẤT', en: 'PRODUCTIVITY'),
                style: TextStyle(
                  color: captionColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                LocaleService.tr('Tập trung', en: 'Focus'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const NotificationBell(),
      ],
    );
  }
}

class _SectionTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _SectionTabs({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    final labels = [
      LocaleService.tr('Hôm nay', en: 'Today'),
      LocaleService.tr('Thống kê', en: 'Stats'),
      LocaleService.tr('Lịch sử', en: 'History'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: _TabPill(
                label: labels[i],
                selected: i == index,
                captionColor: captionColor,
                onTap: () => onChanged(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color captionColor;
  final VoidCallback onTap;

  const _TabPill({
    required this.label,
    required this.selected,
    required this.captionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF06B6D4)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : captionColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayList extends StatelessWidget {
  final FocusProvider provider;
  const _TodayList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todays = provider.history
        .where((s) => !s.startedAt.isBefore(todayStart))
        .toList();

    if (todays.isEmpty) {
      return _EmptyState(
        text: LocaleService.tr(
          'Chưa có phiên focus nào hôm nay. Bắt đầu phiên đầu tiên!',
          en: "No focus sessions yet today. Kick off your first one!",
        ),
        captionColor: captionColor,
      );
    }

    return Column(
      children: [
        for (final s in todays) ...[
          FocusSessionCard(session: s),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _StatsTab extends StatelessWidget {
  final FocusProvider provider;
  const _StatsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final stats = provider.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FocusWeekChart(weekBuckets: stats.weekBuckets),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    LocaleService.tr('Top task tuần này',
                        en: 'Top tasks this week'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    LocaleService.tr('Phút', en: 'Minutes'),
                    style: TextStyle(
                      color: captionColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (stats.topTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    LocaleService.tr(
                      'Chưa có task nào được focus tuần này.',
                      en: 'No tasks focused this week yet.',
                    ),
                    style: TextStyle(color: captionColor),
                  ),
                )
              else
                for (var i = 0; i < stats.topTasks.length; i++) ...[
                  _TopTaskRow(
                    rank: i + 1,
                    title: stats.topTasks[i].taskTitle.isEmpty ||
                            stats.topTasks[i].isUnassigned
                        ? LocaleService.tr(
                            'Không gắn task',
                            en: 'No task linked',
                          )
                        : stats.topTasks[i].taskTitle,
                    minutes: stats.topTasks[i].minutes,
                    sessionCount: stats.topTasks[i].sessionCount,
                    textColor: textColor,
                    captionColor: captionColor,
                  ),
                  if (i < stats.topTasks.length - 1) const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TopTaskRow extends StatelessWidget {
  final int rank;
  final String title;
  final int minutes;
  final int sessionCount;
  final Color textColor;
  final Color captionColor;

  const _TopTaskRow({
    required this.rank,
    required this.title,
    required this.minutes,
    required this.sessionCount,
    required this.textColor,
    required this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Color(0xFF06B6D4),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                LocaleService.tr(
                  '$sessionCount phiên',
                  en: '$sessionCount session${sessionCount == 1 ? '' : 's'}',
                ),
                style: TextStyle(
                  color: captionColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${minutes}m',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final FocusProvider provider;
  const _HistoryTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);

    if (provider.history.isEmpty) {
      return _EmptyState(
        text: LocaleService.tr(
          'Lịch sử trống — phiên đầu tiên của bạn sẽ xuất hiện ở đây.',
          en: "History is empty — your first session will land here.",
        ),
        captionColor: captionColor,
      );
    }

    // Group by day in descending order.
    final byDay = <DateTime, List<FocusSession>>{};
    for (final s in provider.history) {
      final d = s.day;
      byDay.putIfAbsent(d, () => []).add(s);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String dayLabel(DateTime d) {
      if (d == today) return LocaleService.tr('Hôm nay', en: 'Today');
      if (d == today.subtract(const Duration(days: 1))) {
        return LocaleService.tr('Hôm qua', en: 'Yesterday');
      }
      return '${d.day}/${d.month}/${d.year}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final day in days) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
            child: Text(
              dayLabel(day),
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          for (final s in byDay[day]!) ...[
            FocusSessionCard(session: s),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  final Color captionColor;
  const _EmptyState({required this.text, required this.captionColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: captionColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
