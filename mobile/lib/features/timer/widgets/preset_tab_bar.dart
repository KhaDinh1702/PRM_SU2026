import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';

class PresetTabBar extends StatelessWidget {
  final String currentMode;
  final Function(String mode, int minutes) onPresetSelected;

  const PresetTabBar({
    super.key,
    required this.currentMode,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final cardBgColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPresetTab(
              title: 'Focus',
              subtitle: '25M',
              isSelected: currentMode == 'Focus',
              onTap: () => onPresetSelected('Focus', 25),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildPresetTab(
              title: 'Short Break',
              subtitle: '5M',
              isSelected: currentMode == 'Short Break',
              onTap: () => onPresetSelected('Short Break', 5),
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _buildPresetTab(
              title: 'Long Break',
              subtitle: '15M',
              isSelected: currentMode == 'Long Break',
              onTap: () => onPresetSelected('Long Break', 15),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTab({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    Color activeColor;
    if (title == 'Focus') {
      activeColor = const Color(0xFF8B5CF6);
    } else if (title == 'Short Break') {
      activeColor = const Color(0xFF10B981);
    } else {
      activeColor = const Color(0xFF06B6D4);
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: isSelected ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
          border: Border.all(
            color: isSelected ? activeColor.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? Colors.white54 : Colors.black54),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isSelected
                    ? activeColor
                    : (isDark ? Colors.white30 : Colors.black38),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
