import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';

/// Card nền được dùng chung trong các tab của project detail.
class ProjectDetailCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  const ProjectDetailCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.055)
            : Colors.black.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor ??
              (isDark
                  ? Colors.white.withValues(alpha: 0.075)
                  : Colors.black.withValues(alpha: 0.06)),
        ),
      ),
      child: child,
    );
  }
}

/// Widget empty state dùng chung giữa các tab (tasks, chat...).
class ProjectEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  final String? cta;
  final IconData? ctaIcon;
  final VoidCallback? onPressed;

  const ProjectEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    required this.cta,
    this.ctaIcon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 54, color: subTextColor.withValues(alpha: 0.65)),
            const SizedBox(height: 14),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(text,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: subTextColor, fontSize: 13, height: 1.35)),
            if (cta != null && onPressed != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onPressed!,
                icon: Icon(ctaIcon ?? Icons.add_rounded,
                    size: 18, color: Colors.white),
                label: Text(cta!,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pill nhỏ hiển thị status / priority / role với màu nền và viền cùng tông.
/// Dùng chung bởi project card, hero, members tab và tasks tab.
class ProjectStatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final EdgeInsetsGeometry padding;

  const ProjectStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Container glassmorphic wrapper cho project detail bottom sheet.
class ProjectDetailSheetContainer extends StatelessWidget {
  final Color backgroundColor;
  final Color borderColor;
  final List<Widget> children;

  const ProjectDetailSheetContainer({
    super.key,
    required this.backgroundColor,
    required this.borderColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          border: Border.all(color: borderColor),
        ),
        child: Column(children: children),
      ),
    );
  }
}
