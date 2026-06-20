import 'package:flutter/material.dart';

import '../../services/theme_service.dart';

/// Paints the app-wide gradient backdrop used by [MainNavigationScreen].
///
/// Screens that are reached via `Navigator.push` (Notifications, Calendar,
/// Analytics, etc.) used to render with `Scaffold(backgroundColor: transparent)`
/// expecting the underlying nav gradient to show through — that only works
/// when the screen is rendered as a tab. Once pushed as a new route the
/// gradient vanishes and the device shows pure black.
///
/// Wrap the body of those scaffolds with this widget (or set
/// `backgroundColor: Colors.transparent` and stack it as the bottom layer)
/// so the gradient is always present regardless of how the screen is shown.
class AppScaffoldBackground extends StatelessWidget {
  final Widget child;

  const AppScaffoldBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.isDarkMode,
      builder: (context, _) {
        final isDark = ThemeService.isDarkMode.value;
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: ThemeService.getGradientColors(isDark),
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: child,
        );
      },
    );
  }
}
