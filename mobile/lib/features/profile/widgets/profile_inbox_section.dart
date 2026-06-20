import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import 'notifications_preview_card.dart';
import 'profile_section_header.dart';

/// Inbox section: shows the latest unread notifications inline.
class ProfileInboxSection extends StatelessWidget {
  const ProfileInboxSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          label: LocaleService.tr('HỘP THƯ', en: 'INBOX'),
        ),
        const NotificationsPreviewCard(),
      ],
    );
  }
}
