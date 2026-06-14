/// Model đại diện cho dữ liệu dashboard summary — thay thế Map<String, dynamic>
class DashboardSummary {
  final int pendingTasks;
  final int completedTasks;
  final int projects;
  final int totalFocusTimeTodayMinutes;
  final Map<String, dynamic>? nextMeeting;

  const DashboardSummary({
    required this.pendingTasks,
    required this.completedTasks,
    required this.projects,
    required this.totalFocusTimeTodayMinutes,
    this.nextMeeting,
  });

  /// Parse từ JSON response của backend
  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      pendingTasks: _parseInt(json['pendingTasks']),
      completedTasks: _parseInt(json['completedTasks']),
      projects: _parseInt(json['projects']),
      totalFocusTimeTodayMinutes:
          _parseInt(json['totalFocusTimeTodayMinutes']),
      nextMeeting: json['nextMeeting'] is Map<String, dynamic>
          ? json['nextMeeting'] as Map<String, dynamic>
          : null,
    );
  }

  /// Trả về title của cuộc họp tiếp theo
  String get nextMeetingTitle =>
      nextMeeting?['title']?.toString() ?? '';

  /// Trả về mô tả của cuộc họp tiếp theo
  String get nextMeetingDescription =>
      nextMeeting?['description']?.toString() ?? '';

  /// Trả về thời gian bắt đầu của cuộc họp tiếp theo
  DateTime? get nextMeetingStartTime {
    final raw = nextMeeting?['startTime'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  /// Mặc định empty khi chưa load
  static const DashboardSummary empty = DashboardSummary(
    pendingTasks: 0,
    completedTasks: 0,
    projects: 0,
    totalFocusTimeTodayMinutes: 0,
  );

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    return int.tryParse(value.toString()) ?? 0;
  }
}
