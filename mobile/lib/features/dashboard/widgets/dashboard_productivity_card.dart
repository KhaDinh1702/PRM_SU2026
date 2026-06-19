import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/widgets/premium_widgets.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';

class DashboardProductivityCard extends StatelessWidget {
  final int score;
  final double weeklyTrendPercent;

  const DashboardProductivityCard({
    super.key,
    required this.score,
    required this.weeklyTrendPercent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final primary = ThemeService.getPrimaryColor(isDark);
    final trendUp = weeklyTrendPercent >= 0;
    final trendColor = trendUp ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleService.tr('Điểm năng suất', en: 'Productivity Score'),
                  style: TextStyle(
                    color: captionColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        '/100',
                        style: TextStyle(
                          color: captionColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 16,
                        color: trendColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${trendUp ? '+' : ''}${weeklyTrendPercent.round()}% ${LocaleService.tr('tuần này', en: 'this week')}',
                        style: TextStyle(
                          color: trendColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 96,
            height: 96,
            child: CustomPaint(
              painter: _ProgressRingPainter(
                progress: score / 100,
                color: primary,
                trackColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
              child: Center(
                child: Icon(Icons.bolt_rounded, color: primary, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    const stroke = 8.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0, 1),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
