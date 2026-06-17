import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../services/auth_service.dart';
import '../../../services/theme_service.dart';
import '../../../services/locale_service.dart';
import '../../../core/widgets/premium_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  String _selectedRange = 'week'; // 'day', 'week', 'month'

  // Summary data
  int _totalTasks = 0;
  int _completedTasks = 0;
  int _completionRate = 0;
  int _totalFocusMinutes = 0;
  int _totalFocusSessions = 0;

  // Daily stats for chart
  List<Map<String, dynamic>> _dailyStats = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('${AuthService.apiBaseUrl}/analytics/reports?range=$_selectedRange'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = data['summary'] ?? {};
        final daily = data['dailyStats'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _totalTasks = summary['totalTasksCreated'] ?? 0;
            _completedTasks = summary['completedTasksCount'] ?? 0;
            _completionRate = summary['completionRatePercentage'] ?? 0;
            _totalFocusMinutes = summary['totalFocusTimeMinutes'] ?? 0;
            _totalFocusSessions = summary['totalFocusSessionsCount'] ?? 0;
            _dailyStats = daily.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load reports');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onRangeChanged(String range) {
    if (range != _selectedRange) {
      setState(() => _selectedRange = range);
      _loadReports();
    }
  }

  int get _pendingTasks => _totalTasks - _completedTasks;

  String _formatFocusTime(int totalMinutes) {
    if (totalMinutes < 60) return '${totalMinutes}m';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m > 0 ? '${h}h ${m}m' : '${h}h';
  }

  String _formatDayLabel(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final days = [
        LocaleService.tr('CN', en: 'Sun'),
        LocaleService.tr('T2', en: 'Mon'),
        LocaleService.tr('T3', en: 'Tue'),
        LocaleService.tr('T4', en: 'Wed'),
        LocaleService.tr('T5', en: 'Thu'),
        LocaleService.tr('T6', en: 'Fri'),
        LocaleService.tr('T7', en: 'Sat')
      ];
      return '${days[date.weekday % 7]}\n${date.day}/${date.month}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFFEC4899); // Pink for Analytics
    const accentColor = Color(0xFF8B5CF6); // Violet accent

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
            onRefresh: _loadReports,
            color: themeColor,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  FadeInSlide(
                    delayMs: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleService.tr('THỐNG KÊ NĂNG SUẤT',
                              en: 'PRODUCTIVITY STATS'),
                          style: TextStyle(
                            color: captionColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Analytics & Reports',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Range selector pills ---
                  FadeInSlide(
                    delayMs: 80,
                    child: _buildRangeSelector(isDark, themeColor),
                  ),
                  const SizedBox(height: 24),

                  // --- Summary Cards ---
                  _isLoading
                      ? _buildShimmerSummary()
                      : _buildSummarySection(
                          isDark, themeColor, textColor, captionColor),
                  const SizedBox(height: 28),

                  // --- Completion Rate Ring ---
                  _isLoading
                      ? const ShimmerLoading(
                          width: double.infinity, height: 200, borderRadius: 24)
                      : FadeInSlide(
                          delayMs: 350,
                          child: _buildCompletionRingCard(isDark, themeColor,
                              accentColor, textColor, captionColor),
                        ),
                  const SizedBox(height: 28),

                  // --- Focus Time Chart ---
                  FadeInSlide(
                    delayMs: 400,
                    child: Text(
                      LocaleService.tr('BIỂU ĐỒ THỜI GIAN TẬP TRUNG',
                          en: 'FOCUS TIME CHART'),
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
                          width: double.infinity, height: 220, borderRadius: 24)
                      : FadeInSlide(
                          delayMs: 450,
                          child: _buildBarChart(
                              isDark,
                              accentColor,
                              captionColor,
                              textColor,
                              'focusMinutes',
                              LocaleService.tr('phút', en: 'mins')),
                        ),
                  const SizedBox(height: 28),

                  // --- Completed Tasks Chart ---
                  FadeInSlide(
                    delayMs: 500,
                    child: Text(
                      LocaleService.tr('BIỂU ĐỒ TASK HOÀN THÀNH',
                          en: 'COMPLETED TASKS CHART'),
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
                          width: double.infinity, height: 220, borderRadius: 24)
                      : FadeInSlide(
                          delayMs: 550,
                          child: _buildBarChart(
                              isDark,
                              const Color(0xFF10B981),
                              captionColor,
                              textColor,
                              'completedTasks',
                              'tasks'),
                        ),

                  // --- Weekly Performance Summary ---
                  if (!_isLoading && _dailyStats.isNotEmpty) ...[
                    const SizedBox(height: 28),
                    FadeInSlide(
                      delayMs: 600,
                      child: Text(
                        LocaleService.tr('TỔNG QUAN HIỆU SUẤT',
                            en: 'PERFORMANCE SUMMARY'),
                        style: TextStyle(
                          color: captionColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeInSlide(
                      delayMs: 650,
                      child: _buildPerformanceSummaryCard(
                          isDark, themeColor, textColor, captionColor),
                    ),
                  ],

                  // Empty state
                  if (!_isLoading &&
                      _totalTasks == 0 &&
                      _totalFocusSessions == 0) ...[
                    const SizedBox(height: 28),
                    FadeInSlide(
                      delayMs: 400,
                      child: GlassCard(
                        borderRadius: 24,
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: themeColor.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.insights_rounded,
                                  color: themeColor.withOpacity(0.5),
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                LocaleService.tr('Chưa có dữ liệu năng suất',
                                    en: 'No productivity data yet'),
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                LocaleService.tr(
                                    'Bắt đầu hoàn thành công việc để xem báo cáo!',
                                    en: 'Start completing tasks to see your report!'),
                                style: TextStyle(
                                  color: captionColor,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Bottom padding for navbar
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Range Selector ---
  Widget _buildRangeSelector(bool isDark, Color activeColor) {
    final options = [
      {'key': 'day', 'label': LocaleService.tr('Hôm nay', en: 'Today')},
      {'key': 'week', 'label': LocaleService.tr('7 ngày', en: '7 days')},
      {'key': 'month', 'label': LocaleService.tr('30 ngày', en: '30 days')},
    ];

    return Row(
      children: options.map((opt) {
        final isActive = _selectedRange == opt['key'];
        return Expanded(
          child: GestureDetector(
            onTap: () => _onRangeChanged(opt['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? activeColor.withOpacity(0.12)
                    : ThemeService.getCardColor(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isActive
                      ? activeColor.withOpacity(0.3)
                      : ThemeService.getBorderColor(isDark),
                ),
              ),
              child: Center(
                child: Text(
                  opt['label']!,
                  style: TextStyle(
                    color: isActive
                        ? activeColor
                        : ThemeService.getCaptionColor(isDark),
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Shimmer for Summary ---
  Widget _buildShimmerSummary() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.35,
      children: const [
        ShimmerLoading(width: double.infinity, height: double.infinity),
        ShimmerLoading(width: double.infinity, height: double.infinity),
        ShimmerLoading(width: double.infinity, height: double.infinity),
        ShimmerLoading(width: double.infinity, height: double.infinity),
      ],
    );
  }

  // --- Summary Cards ---
  Widget _buildSummarySection(
      bool isDark, Color themeColor, Color textColor, Color captionColor) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.35,
      children: [
        FadeInSlide(
          delayMs: 100,
          child: _buildStatCard(
            icon: Icons.task_alt_rounded,
            label: LocaleService.tr('Hoàn thành', en: 'Completed'),
            value: '$_completedTasks',
            unit: LocaleService.tr('tasks', en: 'tasks'),
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
        ),
        FadeInSlide(
          delayMs: 150,
          child: _buildStatCard(
            icon: Icons.pending_actions_rounded,
            label: LocaleService.tr('Đang chờ', en: 'Pending'),
            value: '$_pendingTasks',
            unit: LocaleService.tr('tasks', en: 'tasks'),
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
        ),
        FadeInSlide(
          delayMs: 200,
          child: _buildStatCard(
            icon: Icons.bolt_rounded,
            label: LocaleService.tr('Thời gian Focus', en: 'Focus time'),
            value: _formatFocusTime(_totalFocusMinutes),
            unit: '',
            color: themeColor,
            isDark: isDark,
          ),
        ),
        FadeInSlide(
          delayMs: 250,
          child: _buildStatCard(
            icon: Icons.hourglass_full_rounded,
            label: LocaleService.tr('Phiên Pomodoro', en: 'Pomodoro sessions'),
            value: '$_totalFocusSessions',
            unit: LocaleService.tr('phiên', en: 'sessions'),
            color: const Color(0xFF8B5CF6),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required bool isDark,
  }) {
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                textBaseline: TextBaseline.alphabetic,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (unit.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      unit,
                      style: TextStyle(fontSize: 11, color: captionColor),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
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

  // --- Completion Rate Ring Card ---
  Widget _buildCompletionRingCard(bool isDark, Color themeColor,
      Color accentColor, Color textColor, Color captionColor) {
    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          // Circular progress ring
          SizedBox(
            width: 120,
            height: 120,
            child: CustomPaint(
              painter: _CompletionRingPainter(
                percentage: _completionRate / 100,
                color: accentColor,
                bgColor: isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.04),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$_completionRate%',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      LocaleService.tr('hoàn thành', en: 'completed'),
                      style: TextStyle(
                        color: captionColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocaleService.tr('Tỷ Lệ Hoàn Thành', en: 'Completion Rate'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProgressRow(
                    LocaleService.tr('Hoàn thành', en: 'Completed'),
                    _completedTasks,
                    const Color(0xFF10B981),
                    isDark),
                const SizedBox(height: 8),
                _buildProgressRow(LocaleService.tr('Đang chờ', en: 'Pending'),
                    _pendingTasks, const Color(0xFFF59E0B), isDark),
                const SizedBox(height: 8),
                _buildProgressRow(LocaleService.tr('Tổng cộng', en: 'Total'),
                    _totalTasks, accentColor, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow(String label, int count, Color color, bool isDark) {
    final captionColor = ThemeService.getCaptionColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: captionColor, fontSize: 12),
        ),
        const Spacer(),
        Text(
          '$count',
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // --- Bar Chart ---
  Widget _buildBarChart(bool isDark, Color barColor, Color captionColor,
      Color textColor, String dataKey, String unit) {
    final allZero = _dailyStats.every((day) => (day[dataKey] ?? 0) == 0);
    if (_dailyStats.isEmpty || allZero) {
      return GlassCard(
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 44,
                color: captionColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                LocaleService.tr('Chưa có dữ liệu thống kê',
                    en: 'No stats data available'),
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                LocaleService.tr('Hãy bắt đầu hoạt động để ghi nhận dữ liệu',
                    en: 'Start active tasks to see details here'),
                style: TextStyle(
                  color: captionColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Find max value for scaling
    double maxVal = 0;
    for (final day in _dailyStats) {
      final val = (day[dataKey] ?? 0).toDouble();
      if (val > maxVal) maxVal = val;
    }
    if (maxVal == 0) maxVal = 1; // avoid division by zero

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _dailyStats.map((day) {
                final val = (day[dataKey] ?? 0).toDouble();
                final heightFraction = val / maxVal;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${val.toInt()}',
                              style: TextStyle(
                                color: barColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          height: max(4.0, 130.0 * heightFraction),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                barColor,
                                barColor.withOpacity(0.5),
                              ],
                            ),
                            boxShadow: val > 0
                                ? [
                                    BoxShadow(
                                      color: barColor.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Day labels
          Row(
            children: _dailyStats.map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    _formatDayLabel(day['date']),
                    style: TextStyle(
                      color: captionColor,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- Performance Summary ---
  Widget _buildPerformanceSummaryCard(
      bool isDark, Color themeColor, Color textColor, Color captionColor) {
    // Calculate daily averages
    final totalDays = _dailyStats.length;
    final avgTasks =
        totalDays > 0 ? (_completedTasks / totalDays).toStringAsFixed(1) : '0';
    final avgFocus = totalDays > 0
        ? (_totalFocusMinutes / totalDays).toStringAsFixed(0)
        : '0';

    // Find best day (most tasks completed)
    String bestDay = '—';
    int bestCount = 0;
    for (final day in _dailyStats) {
      final count = (day['completedTasks'] ?? 0) as int;
      if (count > bestCount) {
        bestCount = count;
        bestDay = _formatDayLabel(day['date']).replaceAll('\n', ' ');
      }
    }

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: themeColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Weekly Performance',
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(
              Icons.speed_rounded,
              LocaleService.tr('TB Tasks/ngày', en: 'Avg Tasks/day'),
              avgTasks,
              const Color(0xFF10B981),
              isDark),
          const SizedBox(height: 10),
          _buildSummaryRow(
              Icons.timer_rounded,
              LocaleService.tr('TB Focus/ngày', en: 'Avg Focus/day'),
              '${avgFocus}m',
              const Color(0xFF8B5CF6),
              isDark),
          const SizedBox(height: 10),
          _buildSummaryRow(
              Icons.star_rounded,
              LocaleService.tr('Ngày làm tốt nhất', en: 'Best Day'),
              bestDay,
              const Color(0xFFF59E0B),
              isDark),
          const SizedBox(height: 10),
          _buildSummaryRow(
              Icons.whatshot_rounded,
              LocaleService.tr('Tổng phiên Focus', en: 'Total Focus Sessions'),
              '$_totalFocusSessions ${LocaleService.tr('phiên', en: 'sessions')}',
              themeColor,
              isDark),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
      IconData icon, String label, String value, Color color, bool isDark) {
    final captionColor = ThemeService.getCaptionColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: captionColor, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// --- Custom Painter for Circular Progress Ring ---
class _CompletionRingPainter extends CustomPainter {
  final double percentage;
  final Color color;
  final Color bgColor;

  _CompletionRingPainter({
    required this.percentage,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // Background ring
    final bgPaint = Paint()
      ..color = bgColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [color.withOpacity(0.6), color],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * percentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow dot at the end of arc
    if (percentage > 0) {
      final endAngle = -pi / 2 + sweepAngle;
      final dotX = center.dx + radius * cos(endAngle);
      final dotY = center.dy + radius * sin(endAngle);

      final dotPaint = Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(dotX, dotY), 5, dotPaint);
      canvas.drawCircle(Offset(dotX, dotY), 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _CompletionRingPainter old) {
    return old.percentage != percentage;
  }
}
