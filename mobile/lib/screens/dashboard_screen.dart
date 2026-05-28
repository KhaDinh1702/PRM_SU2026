import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/premium_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _summary = {
    'pendingTasks': 0,
    'completedTasks': 0,
    'projects': 0,
    'totalFocusTimeTodayMinutes': 0,
    'nextMeeting': null
  };

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('https://prm-tan.vercel.app/api/dashboard/summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _summary = jsonDecode(response.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception();
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

    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkMode,
      builder: (context, isDark, child) {
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TỔNG QUAN TIẾN TRÌNH',
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
                                'Cần làm',
                                '${_summary['pendingTasks']}',
                                'công việc',
                                Icons.playlist_add_check_rounded,
                                themeColor,
                                isDark,
                              ),
                            ),
                            FadeInSlide(
                              delayMs: 200,
                              child: _buildSummaryCard(
                                'Hoàn thành',
                                '${_summary['completedTasks']}',
                                'công việc',
                                Icons.task_alt_rounded,
                                const Color(0xFF10B981),
                                isDark,
                              ),
                            ),
                            FadeInSlide(
                              delayMs: 300,
                              child: _buildSummaryCard(
                                'Dự án tham gia',
                                '${_summary['projects']}',
                                'dự án',
                                Icons.dns_outlined,
                                const Color(0xFF06B6D4),
                                isDark,
                              ),
                            ),
                            FadeInSlide(
                              delayMs: 400,
                              child: _buildSummaryCard(
                                'Tập trung hôm nay',
                                '${_summary['totalFocusTimeTodayMinutes']}',
                                'phút',
                                Icons.bolt,
                                accentColor,
                                isDark,
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 32),

                  // Next meeting card
                  FadeInSlide(
                    delayMs: 450,
                    child: Text(
                      'LỊCH HỌP SẮP TỚI',
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
                      ? const ShimmerLoading(width: double.infinity, height: 110)
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

  Widget _buildSummaryCard(String title, String count, String unit, IconData icon, Color color, bool isDark) {
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return GlassCard(
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
    );
  }

  Widget _buildNextMeetingCard(Color color, bool isDark) {
    final meeting = _summary['nextMeeting'];
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(22),
      child: meeting == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Không có cuộc họp nào sắp diễn ra! 🎉',
                  style: TextStyle(color: captionColor, fontSize: 14),
                ),
              ),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.videocam_rounded, color: color, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting['title'] ?? 'Cuộc họp không có tên',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        meeting['description']?.toString().isNotEmpty == true
                            ? meeting['description']
                            : 'Không có mô tả',
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
                          Icon(Icons.access_time_rounded, color: captionColor, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _formatMeetingTime(meeting['startTime']),
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

  String _formatMeetingTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} - ${date.day}/${date.month}/${date.year}';
    } catch (_) {}
    return '';
  }
}
