import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import '../../subscriptions/screens/subscription_screen.dart';
import 'profile_nav_tile.dart';
import 'profile_section_header.dart';

class ProfileSubscriptionCard extends StatelessWidget {
  const ProfileSubscriptionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          label: LocaleService.tr('GOI TAI KHOAN', en: 'PLAN'),
        ),
        ProfileNavTile(
          icon: Icons.workspace_premium_rounded,
          iconColor: const Color(0xFFF59E0B),
          title: LocaleService.tr('FlowMate Pro', en: 'FlowMate Pro'),
          subtitle: LocaleService.tr(
            'Thanh toan bang PayOS de mo khoa tinh nang Pro',
            en: 'Pay with PayOS to unlock Pro features',
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            );
          },
        ),
      ],
    );
  }
}
