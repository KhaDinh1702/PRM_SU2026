import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/focus_session.dart';
import '../providers/focus_provider.dart';

/// The main interactive card on the focus screen: task pill, mode presets,
/// big countdown digits with a progress ring, and start/pause/cancel
/// buttons. Stateless — it reads everything from [provider] and forwards
/// taps through the supplied callbacks.
class FocusActiveCard extends StatelessWidget {
  final FocusProvider provider;
  final VoidCallback onPickTask;
  final VoidCallback onEditDuration;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onSkipBreak;

  static const Color _focusAccent = Color(0xFF06B6D4);
  static const Color _breakAccent = Color(0xFF10B981);

  const FocusActiveCard({
    super.key,
    required this.provider,
    required this.onPickTask,
    required this.onEditDuration,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onSkipBreak,
  });

  Color get _accent =>
      provider.mode.isBreak ? _breakAccent : _focusAccent;

  String _fmtClock(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _modeLabel() {
    switch (provider.mode) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          _TaskPill(
            taskTitle: provider.taskTitle,
            onTap: provider.hasActiveSession ? null : onPickTask,
            accent: _accent,
            textColor: textColor,
            captionColor: captionColor,
          ),
          const SizedBox(height: 18),
          _ModePresets(
            mode: provider.mode,
            disabled: provider.hasActiveSession,
            onSelected: provider.setMode,
            onCustom: onEditDuration,
            captionColor: captionColor,
            textColor: textColor,
            accent: _accent,
          ),
          const SizedBox(height: 22),
          _TimerRing(
            secondsRemaining: provider.secondsRemaining,
            progress: provider.progress,
            modeLabel: _modeLabel(),
            isPaused: provider.isPaused,
            isBreakReady: provider.isBreakReady,
            canEdit: provider.isIdle,
            onTap: onEditDuration,
            accent: _accent,
            textColor: textColor,
            captionColor: captionColor,
            isDark: isDark,
            clockText: _fmtClock(
              provider.isBreakReady
                  ? provider.totalSeconds
                  : provider.secondsRemaining,
            ),
          ),
          const SizedBox(height: 20),
          _ActionRow(
            provider: provider,
            accent: _accent,
            onStart: onStart,
            onPause: onPause,
            onResume: onResume,
            onCancel: onCancel,
            onSkipBreak: onSkipBreak,
            captionColor: captionColor,
          ),
        ],
      ),
    );
  }
}

class _TaskPill extends StatelessWidget {
  final String? taskTitle;
  final VoidCallback? onTap;
  final Color accent;
  final Color textColor;
  final Color captionColor;

  const _TaskPill({
    required this.taskTitle,
    required this.onTap,
    required this.accent,
    required this.textColor,
    required this.captionColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasTask = taskTitle != null && taskTitle!.isNotEmpty;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withValues(alpha: 0.36)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasTask ? Icons.flag_rounded : Icons.add_rounded,
                size: 14,
                color: accent,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  hasTask
                      ? taskTitle!
                      : LocaleService.tr(
                          'Chọn task để focus',
                          en: 'Pick a task to focus on',
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasTask ? textColor : accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 14, color: accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ModePresets extends StatelessWidget {
  final FocusSessionMode mode;
  final bool disabled;
  final void Function(FocusSessionMode mode) onSelected;

  /// Called when the user taps the Custom chip — the host opens a
  /// duration picker so the user can dial in any value 1–180 minutes.
  final VoidCallback onCustom;

  final Color captionColor;
  final Color textColor;
  final Color accent;

  const _ModePresets({
    required this.mode,
    required this.disabled,
    required this.onSelected,
    required this.onCustom,
    required this.captionColor,
    required this.textColor,
    required this.accent,
  });

  static const List<FocusSessionMode> _presets = [
    FocusSessionMode.focus,
    FocusSessionMode.shortBreak,
    FocusSessionMode.longBreak,
  ];

  String _labelFor(FocusSessionMode m) {
    switch (m) {
      case FocusSessionMode.focus:
        return LocaleService.tr('Tập trung', en: 'Focus');
      case FocusSessionMode.shortBreak:
        return LocaleService.tr('Nghỉ 5p', en: 'Short');
      case FocusSessionMode.longBreak:
        return LocaleService.tr('Nghỉ 15p', en: 'Long');
      case FocusSessionMode.custom:
        return LocaleService.tr('Tuỳ chỉnh', en: 'Custom');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final preset in _presets)
          _ModeChip(
            label: _labelFor(preset),
            selected: mode == preset,
            disabled: disabled,
            accent: accent,
            textColor: textColor,
            captionColor: captionColor,
            onTap: disabled ? null : () => onSelected(preset),
          ),
        _ModeChip(
          label: _labelFor(FocusSessionMode.custom),
          selected: mode == FocusSessionMode.custom,
          disabled: disabled,
          accent: accent,
          textColor: textColor,
          captionColor: captionColor,
          onTap: disabled ? null : onCustom,
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final Color accent;
  final Color textColor;
  final Color captionColor;
  final VoidCallback? onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.disabled,
    required this.accent,
    required this.textColor,
    required this.captionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? Colors.white
        : (disabled ? captionColor.withValues(alpha: 0.5) : textColor);
    final bg = selected
        ? accent
        : accent.withValues(alpha: disabled ? 0.04 : 0.10);
    final border = selected
        ? accent
        : accent.withValues(alpha: disabled ? 0.12 : 0.32);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: border),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerRing extends StatelessWidget {
  final int secondsRemaining;
  final double progress;
  final String modeLabel;
  final String clockText;
  final bool isPaused;
  final bool isBreakReady;
  final bool canEdit;
  final VoidCallback onTap;
  final Color accent;
  final Color textColor;
  final Color captionColor;
  final bool isDark;

  const _TimerRing({
    required this.secondsRemaining,
    required this.progress,
    required this.modeLabel,
    required this.clockText,
    required this.isPaused,
    required this.isBreakReady,
    required this.canEdit,
    required this.onTap,
    required this.accent,
    required this.textColor,
    required this.captionColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress.isFinite ? progress : 0,
              strokeWidth: 10,
              backgroundColor: accent.withValues(alpha: 0.12),
              color: accent,
              strokeCap: StrokeCap.round,
            ),
          ),
          Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: canEdit ? onTap : null,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 180,
                height: 180,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      modeLabel.toUpperCase(),
                      style: TextStyle(
                        color: captionColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      clockText,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 46,
                        fontWeight: FontWeight.w900,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isPaused)
                      Text(
                        LocaleService.tr('Đang tạm dừng', en: 'Paused'),
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    else if (isBreakReady)
                      Text(
                        LocaleService.tr('Sẵn sàng nghỉ',
                            en: 'Break ready'),
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    else if (canEdit)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined,
                              color: captionColor, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            LocaleService.tr('chạm để sửa',
                                en: 'tap to edit'),
                            style: TextStyle(
                              color: captionColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final FocusProvider provider;
  final Color accent;
  final Color captionColor;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onSkipBreak;

  const _ActionRow({
    required this.provider,
    required this.accent,
    required this.captionColor,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onSkipBreak,
  });

  @override
  Widget build(BuildContext context) {
    final isIdle = provider.isIdle;
    final isRunning = provider.isRunning;
    final isPaused = provider.isPaused;
    final isBreakReady = provider.isBreakReady;

    String primaryLabel;
    VoidCallback primaryOnTap;
    if (isBreakReady) {
      primaryLabel = LocaleService.tr('Bắt đầu nghỉ', en: 'Start break');
      primaryOnTap = onStart;
    } else if (isRunning) {
      primaryLabel = LocaleService.tr('Tạm dừng', en: 'Pause');
      primaryOnTap = onPause;
    } else if (isPaused) {
      primaryLabel = LocaleService.tr('Tiếp tục', en: 'Resume');
      primaryOnTap = onResume;
    } else {
      primaryLabel = LocaleService.tr('Bắt đầu', en: 'Start');
      primaryOnTap = onStart;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 48,
          child: FilledButton.icon(
            onPressed: primaryOnTap,
            icon: Icon(
              isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 22,
            ),
            label: Text(
              primaryLabel,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        if (!isIdle)
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: isBreakReady ? onSkipBreak : onCancel,
              icon: Icon(
                isBreakReady ? Icons.skip_next_rounded : Icons.stop_rounded,
                size: 20,
              ),
              label: Text(
                isBreakReady
                    ? LocaleService.tr('Bỏ qua', en: 'Skip')
                    : LocaleService.tr('Huỷ', en: 'Cancel'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: captionColor,
                side: BorderSide(color: captionColor.withValues(alpha: 0.32)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
