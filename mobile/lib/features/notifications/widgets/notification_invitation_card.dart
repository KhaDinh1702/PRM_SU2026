import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../models/notification_model.dart';

/// Card with Accept/Reject CTAs for pending project invitations.
class NotificationInvitationCard extends StatelessWidget {
  final NotificationModel invite;
  final Future<void> Function(String action) onRespond;

  const NotificationInvitationCard({
    super.key,
    required this.invite,
    required this.onRespond,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final cardBg = ThemeService.getCardColor(isDark);
    final accent = invite.typeColor;
    final projectId = invite.invitationProjectId;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.10 : 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.group_add_rounded, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invite.invitationProjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleService.tr(
                        '${invite.senderName} đã mời bạn tham gia',
                        en: '${invite.senderName} invited you to join',
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: projectId.isEmpty
                      ? null
                      : () => onRespond('reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    LocaleService.tr('Từ chối', en: 'Decline'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: projectId.isEmpty
                      ? null
                      : () => onRespond('accept'),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(
                    LocaleService.tr('Chấp nhận', en: 'Accept'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
