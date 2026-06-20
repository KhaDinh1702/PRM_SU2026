import 'package:flutter/material.dart';

import '../../../services/theme_service.dart';

/// Custom on/off switch used inside [ProfileToggleTile].
///
/// The Material 3 `Switch.adaptive` rendered the thumb at near-zero contrast
/// on this app's theme (dark thumb on dark off-track), so this widget draws
/// an explicit white thumb on a theme-aware track. An optional [thumbIcon]
/// pair lets each tile show a sun/moon style glyph inside the thumb.
class ProfileSwitch extends StatelessWidget {
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;
  final IconData? onIcon;
  final IconData? offIcon;

  static const double _width = 52;
  static const double _height = 30;
  static const double _thumbSize = 24;
  static const Duration _animation = Duration(milliseconds: 220);

  const ProfileSwitch({
    super.key,
    required this.value,
    required this.activeColor,
    required this.onChanged,
    this.onIcon,
    this.offIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final trackOff = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.black.withValues(alpha: 0.16);
    final icon = value ? onIcon : offIcon;
    final iconTint = value ? activeColor : trackOff.withValues(alpha: 1);

    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: _animation,
          curve: Curves.easeOut,
          width: _width,
          height: _height,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value ? activeColor : trackOff,
            borderRadius: BorderRadius.circular(_height),
            boxShadow: value
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: AnimatedAlign(
            duration: _animation,
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: _thumbSize,
              height: _thumbSize,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: icon == null
                  ? null
                  : Icon(icon, size: 14, color: iconTint),
            ),
          ),
        ),
      ),
    );
  }
}
