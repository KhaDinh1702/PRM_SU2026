import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';
import '../../../services/locale_service.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../features/dashboard/models/dashboard_summary.dart';
import '../../../features/dashboard/services/dashboard_service.dart';

class DashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onTabSelect;
  const DashboardScreen({super.key, this.onTabSelect});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dashboardService = const DashboardService();

  bool _isLoading = true;
  DashboardSummary _summary = DashboardSummary.empty;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Gọi qua DashboardService — không http trực tiếp trong widget
      final summary = await _dashboardService.getSummary();
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF8B5CF6); // Premium Cyber Violet
    const accentColor = Color(0xFFF43F5E); // Cyber Pink

    return ListenableBuilder(
      listenable: Listenable.merge(
          [ThemeService.isDarkMode, LocaleService.languageCode]),
      builder: (context, child) {
        final isDark = ThemeService.isDarkMode.value;
        final textColor = ThemeService.getTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: RefreshIndicator(
            onRefresh: _loadSummary,
            color: themeColor,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FadeInSlide(
                    delayMs: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              LocaleService.tr('TỔNG QUAN TIẾN TRÌNH',
                                  en: 'PROGRESS OVERVIEW'),
                              style: TextStyle(
                                color: captionColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'FlowMate Dashboard',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        // Language Switcher
                        GestureDetector(
                          onTap: LocaleService.toggleLanguage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: themeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: themeColor.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.language,
                                    color: themeColor, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  LocaleService.languageCode.value
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: themeColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // UI/UX TẦM CAO MỚI: Skeleton Shimmer Loading hoặc Stagger Grid Cards
                  _isLoading
                      ? _buildShimmerGrid()
                      : GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.25,
                          children: [
                            FadeInSlide(
                              delayMs: 100,
                              child: _buildSummaryCard(
                                LocaleService.tr('Cần làm', en: 'Pending'),
                                '${_summary.pendingTasks}',
                                LocaleService.tr('công việc', en: 'tasks'),
                                Icons.playlist_add_check_rounded,
                                themeColor,
                                isDark,
                                onTap: () => widget.onTabSelect?.call(1),
                              ),
                            ),
                            FadeInSlide(
                              delayMs: 200,
                              child: _buildSummaryCard(
                                LocaleService.tr('Hoàn thành', en: 'Completed'),
                                '${_summary.completedTasks}',
                                LocaleService.tr('công việc', en: 'tasks'),
                                Icons.task_alt_rounded,
                                const Color(0xFF10B981),
                                isDark,
                                onTap: () => widget.onTabSelect?.call(1),
                              ),
                            ),
                            FadeInSlide(
                              delayMs: 300,
                              child: _buildSummaryCard(
                                LocaleService.tr('Dự án tham gia',
                                    en: 'Projects joined'),
                                '${_summary.projects}',
                                LocaleService.tr('dự án', en: 'projects'),
                                Icons.dns_outlined,
                                const Color(0xFF06B6D4),
                                isDark,
                                onTap: () => widget.onTabSelect?.call(3),
                              ),
                            ),
                            FadeInSlide(
                              delayMs: 400,
                              child: _buildSummaryCard(
                                LocaleService.tr('Tập trung hôm nay',
                                    en: 'Focus today'),
                                '${_summary.totalFocusTimeTodayMinutes}',
                                LocaleService.tr('phút', en: 'mins'),
                                Icons.bolt,
                                accentColor,
                                isDark,
                                onTap: () => widget.onTabSelect?.call(2),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 32),

                  // Next meeting card
                  FadeInSlide(
                    delayMs: 450,
                    child: Text(
                      LocaleService.tr('LỊCH HỌP SẮP TỚI',
                          en: 'UPCOMING MEETING'),
                      style: TextStyle(
                        color: captionColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoading
                      ? const ShimmerLoading(
                          width: double.infinity, height: 110)
                      : FadeInSlide(
                          delayMs: 500,
                          child: _buildNextMeetingCard(accentColor, isDark),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Khung xương Shimmer thay thế Loading tròn thô kệch
  Widget _buildShimmerGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: const [
        ShimmerLoading(width: double.infinity, height: double.infinity),
        ShimmerLoading(width: double.infinity, height: double.infinity),
        ShimmerLoading(width: double.infinity, height: double.infinity),
        ShimmerLoading(width: double.infinity, height: double.infinity),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String count, String unit,
      IconData icon, Color color, bool isDark, {VoidCallback? onTap}) {
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                )
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  textBaseline: TextBaseline.alphabetic,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  children: [
                    Text(
                      count,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 12,
                        color: captionColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: subTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextMeetingCard(Color color, bool isDark) {
    // Dùng getter từ DashboardSummary model thay vì Map tùy tiện
    final hasMeeting = _summary.nextMeeting != null;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(22),
      child: !hasMeeting
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.event_available_rounded,
                      color: Color(0xFF10B981),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleService.tr('Lịch trình trống', en: 'Schedule Clear'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          LocaleService.tr('Không có cuộc họp nào sắp diễn ra.',
                              en: 'No upcoming meetings scheduled.'),
                          style: TextStyle(
                            fontSize: 12,
                            color: subTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.videocam_rounded, color: color, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dùng getter từ model thay vì map['field']
                      Text(
                        _summary.nextMeetingTitle.isNotEmpty
                            ? _summary.nextMeetingTitle
                            : LocaleService.tr('Cuộc họp không có tên',
                                en: 'Untitled meeting'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _summary.nextMeetingDescription.isNotEmpty
                            ? _summary.nextMeetingDescription
                            : LocaleService.tr('Không có mô tả',
                                en: 'No description'),
                        style: TextStyle(
                          fontSize: 12,
                          color: subTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              color: captionColor, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _formatMeetingTime(
                                _summary.nextMeetingStartTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: captionColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  /// Format thời gian cuộc họp từ DateTime (đã parse ở model)
  String _formatMeetingTime(DateTime? date) {
    if (date == null) return '';
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}/${date.year}';
  }
}
