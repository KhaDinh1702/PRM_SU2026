import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';

class ProjectDetailFab extends StatelessWidget {
  final VoidCallback onCreateTask;
  final VoidCallback onCreateMilestone;
  final VoidCallback onInviteMember;

  const ProjectDetailFab({
    super.key,
    required this.onCreateTask,
    required this.onCreateMilestone,
    required this.onInviteMember,
  });

  void _showActionSheet(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final primary = ThemeService.getPrimaryColor(isDark);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeService.getDialogBackgroundColor(isDark),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: ThemeService.getBorderColor(isDark)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ThemeService.getCaptionColor(isDark)
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                _ActionTile(
                  icon: Icons.add_task_rounded,
                  label: LocaleService.tr('Tạo task', en: 'Create Task'),
                  color: primary,
                  textColor: textColor,
                  onTap: () {
                    Navigator.pop(context);
                    onCreateTask();
                  },
                ),
                _ActionTile(
                  icon: Icons.flag_rounded,
                  label: LocaleService.tr('Tạo milestone', en: 'Create Milestone'),
                  color: const Color(0xFFF59E0B),
                  textColor: textColor,
                  onTap: () {
                    Navigator.pop(context);
                    onCreateMilestone();
                  },
                ),
                _ActionTile(
                  icon: Icons.person_add_alt_rounded,
                  label: LocaleService.tr('Mời thành viên', en: 'Invite Member'),
                  color: const Color(0xFF8B5CF6),
                  textColor: textColor,
                  onTap: () {
                    Navigator.pop(context);
                    onInviteMember();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = ThemeService.getPrimaryColor(
      ThemeService.isDarkMode.value,
    );

    return FloatingActionButton(
      onPressed: () => _showActionSheet(context),
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 6,
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
      onTap: onTap,
    );
  }
}
