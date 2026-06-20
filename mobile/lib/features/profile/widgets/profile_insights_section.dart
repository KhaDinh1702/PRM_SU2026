import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';
import 'analytics_preview_card.dart';
import 'calendar_preview_card.dart';
import 'profile_section_header.dart';

/// "Insights" section: Calendar + Analytics preview cards.
///
/// Exposes a [GlobalKey] for each card so the screen-level pull-to-refresh
/// can fan reloads out to them.
class ProfileInsightsSection extends StatelessWidget {
  final GlobalKey<CalendarPreviewCardState>? calendarKey;
  final GlobalKey<AnalyticsPreviewCardState>? analyticsKey;

  const ProfileInsightsSection({
    super.key,
    this.calendarKey,
    this.analyticsKey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileSectionHeader(
          label: LocaleService.tr('TỔNG QUAN', en: 'INSIGHTS'),
        ),
        CalendarPreviewCard(key: calendarKey),
        const SizedBox(height: 10),
        AnalyticsPreviewCard(key: analyticsKey),
      ],
    );
  }
}
