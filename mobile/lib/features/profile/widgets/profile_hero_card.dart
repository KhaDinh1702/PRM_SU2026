import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';

/// Hero card at the top of the Profile screen.
///
/// Shows the user's avatar (gradient circle with initial), `@username`,
/// email and the "X/2 username changes left" status pill. A single
/// "Edit username" button opens the dedicated change sheet — keeping the
/// rare action out of the main scroll.
class ProfileHeroCard extends StatelessWidget {
  final String username;
  final String email;
  final String? fullName;
  final String avatarLetter;
  final int usernameChangesRemaining;
  final VoidCallback onEditUsername;

  const ProfileHeroCard({
    super.key,
    required this.username,
    required this.email,
    required this.fullName,
    required this.avatarLetter,
    required this.usernameChangesRemaining,
    required this.onEditUsername,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final cardBg = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final activeColor = ThemeService.getPrimaryColor(isDark);

    final displayHandle = username.isNotEmpty
        ? '@$username'
        : LocaleService.tr('Chưa đặt username', en: 'No username set');
    final displayName = (fullName ?? '').trim().isEmpty
        ? LocaleService.tr('Người dùng FlowMate',
            en: 'FlowMate member')
        : fullName!.trim();
    final canEdit = usernameChangesRemaining > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: activeColor.withValues(alpha: isDark ? 0.06 : 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _Avatar(letter: avatarLetter, color: activeColor),
          const SizedBox(height: 14),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayHandle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: activeColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: subTextColor, fontSize: 12),
          ),
          const SizedBox(height: 16),
          _ChangesBadge(
            remaining: usernameChangesRemaining,
            accent: activeColor,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canEdit ? onEditUsername : null,
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: Text(
                LocaleService.tr('Đổi username', en: 'Edit username'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: activeColor,
                side: BorderSide(color: activeColor.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String letter;
  final Color color;

  const _Avatar({required this.letter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ChangesBadge extends StatelessWidget {
  final int remaining;
  final Color accent;

  const _ChangesBadge({required this.remaining, required this.accent});

  @override
  Widget build(BuildContext context) {
    final exhausted = remaining == 0;
    final color = exhausted ? const Color(0xFFEF4444) : accent;
    final label = exhausted
        ? LocaleService.tr(
            'Đã hết lượt đổi tháng này',
            en: 'No username changes left this month',
          )
        : LocaleService.tr(
            'Còn $remaining/2 lượt đổi tháng này',
            en: '$remaining/2 changes left this month',
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            exhausted ? Icons.block_rounded : Icons.swap_horiz_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
