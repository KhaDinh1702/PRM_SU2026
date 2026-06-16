import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';
import '../../../services/locale_service.dart';
import '../models/forest_tree.dart';

class ForestDialogContent extends StatelessWidget {
  final List<ForestTree> trees;
  const ForestDialogContent({super.key, required this.trees});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);

    // Filter today's trees
    final now = DateTime.now();
    final todayTrees = trees.where((tree) {
      return tree.timestamp.year == now.year &&
          tree.timestamp.month == now.month &&
          tree.timestamp.day == now.day;
    }).toList();

    final successCount = todayTrees.where((t) => t.isSuccess).length;
    final failCount = todayTrees.where((t) => !t.isSuccess).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Statistics section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF10B981),
              value: '$successCount',
              label: LocaleService.tr('Thành công', en: 'Succeeded'),
              textColor: textColor,
              subTextColor: subTextColor,
            ),
            _buildStatItem(
              icon: Icons.cancel_rounded,
              color: Colors.redAccent,
              value: '$failCount',
              label: LocaleService.tr('Héo úa', en: 'Withered'),
              textColor: textColor,
              subTextColor: subTextColor,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          LocaleService.tr('KHU RỪNG HÔM NAY', en: 'TODAY\'S FOREST'),
          style: TextStyle(
            color: ThemeService.getCaptionColor(isDark),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        // Grid of trees
        if (todayTrees.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Column(
              children: [
                const Text(
                  '🪹',
                  style: TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 8),
                Text(
                  LocaleService.tr(
                    'Khu rừng trống. Hãy bắt đầu gieo hạt tập trung!',
                    en: 'Forest is empty. Start planting by focusing!',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: todayTrees.map((tree) {
              return Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                  ),
                ),
                child: Center(
                  child: Tooltip(
                    message: '${tree.mode} - ${tree.durationSeconds ~/ 60}m',
                    child: Text(
                      tree.isSuccess ? '🌳' : '🪵',
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: subTextColor,
          ),
        ),
      ],
    );
  }
}
