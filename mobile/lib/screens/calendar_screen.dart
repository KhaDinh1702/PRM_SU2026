import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/locale_service.dart';
import '../widgets/premium_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _isLoading = true;
  List<dynamic> _events = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _eventType = 'reminder';
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('https://prm-tan.vercel.app/api/calendar/events'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _events = jsonDecode(response.body);
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

  Future<void> _selectDateTime(
      BuildContext context, StateSetter setDialogState) async {
    final now = DateTime.now();
    final initialDate =
        _selectedDateTime.isBefore(now) ? now : _selectedDateTime;

    // Show Material Date Picker
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ThemeService.isDarkMode.value
                ? const ColorScheme.dark(
                    primary: Color(0xFF10B981),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF10B981),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    // Show Material Time Picker
    if (!context.mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ThemeService.isDarkMode.value
                ? const ColorScheme.dark(
                    primary: Color(0xFF10B981),
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Color(0xFF10B981),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    final temporaryDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    final finalNow = DateTime.now();
    setDialogState(() {
      if (temporaryDateTime.isBefore(finalNow)) {
        _selectedDateTime = finalNow;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleService.tr(
                'Thời gian ở quá khứ đã được tự động chuyển về hiện tại!',
                en: 'Past time was automatically changed to current time!')),
            backgroundColor: Colors.amber,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _selectedDateTime = temporaryDateTime;
      }
    });
  }

  Future<void> _createEvent() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    // Validate lại trước khi gửi lên server, nếu nhỏ hơn thời gian thực tế thì tự động set về hiện tại
    final now = DateTime.now();
    if (_selectedDateTime.isBefore(now)) {
      _selectedDateTime = now;
    }

    final startTime = _selectedDateTime.toUtc().toIso8601String();
    final endTime = _selectedDateTime
        .add(const Duration(hours: 1))
        .toUtc()
        .toIso8601String();

    try {
      final token = await AuthService.getToken();
      final response = await http
          .post(
            Uri.parse('https://prm-tan.vercel.app/api/calendar/events'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'title': title,
              'description': _descController.text.trim(),
              'startTime': startTime,
              'endTime': endTime,
              'type': _eventType
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        _titleController.clear();
        _descController.clear();
        setState(() {
          _selectedDateTime = DateTime.now();
        });
        _loadEvents();
      }
    } catch (_) {}
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse('https://prm-tan.vercel.app/api/calendar/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleService.tr('Đã xóa sự kiện thành công!',
                  en: 'Event deleted successfully!')),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        _loadEvents();
      } else {
        final errData = jsonDecode(response.body);
        throw Exception(errData['error'] ??
            LocaleService.tr('Xóa thất bại', en: 'Deletion failed'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${LocaleService.tr('Lỗi khi xóa sự kiện:', en: 'Error deleting event:')} $e'),
            backgroundColor: Colors.amber[900],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCreateEventDialog() {
    // Luôn "bắt thời gian thật" khi mở hộp thoại tạo sự kiện mới
    setState(() {
      _selectedDateTime = DateTime.now();
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = ThemeService.isDarkMode.value;
            final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
            final textColor = ThemeService.getTextColor(isDark);
            final subTextColor = ThemeService.getSubTextColor(isDark);
            final captionColor = ThemeService.getCaptionColor(isDark);

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: AlertDialog(
                backgroundColor: dialogBg.withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.08)),
                ),
                title: Text(
                  LocaleService.tr('TẠO SỰ KIỆN MỚI', en: 'CREATE NEW EVENT'),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textColor,
                      letterSpacing: 1.5),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PremiumInputField(
                      controller: _titleController,
                      label: LocaleService.tr('Tiêu đề sự kiện *',
                          en: 'Event title *'),
                      hintText: LocaleService.tr('Nhập tiêu đề...',
                          en: 'Enter title...'),
                      prefixIcon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 14),
                    PremiumInputField(
                      controller: _descController,
                      label: LocaleService.tr('Mô tả ngắn',
                          en: 'Short description'),
                      hintText: LocaleService.tr('Nhập mô tả chi tiết...',
                          en: 'Enter detailed description...'),
                      prefixIcon: Icons.description_outlined,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.02)
                            : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.06)
                                : Colors.black.withOpacity(0.06)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              LocaleService.tr('Loại sự kiện:',
                                  en: 'Event type:'),
                              style: TextStyle(
                                  color: subTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _eventType,
                              dropdownColor: dialogBg,
                              icon: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: subTextColor),
                              items: <String>['reminder', 'meeting', 'other']
                                  .map((String value) {
                                Color dotColor = const Color(0xFF10B981);
                                if (value == 'meeting') {
                                  dotColor = const Color(0xFF06B6D4);
                                } else if (value == 'other') {
                                  dotColor = const Color(0xFF8B5CF6);
                                }
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                            color: dotColor,
                                            shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        value == 'reminder'
                                            ? LocaleService.tr('Nhắc nhở',
                                                en: 'Reminder')
                                            : (value == 'meeting'
                                                ? LocaleService.tr('Cuộc họp',
                                                    en: 'Meeting')
                                                : LocaleService.tr('Khác',
                                                    en: 'Other')),
                                        style: TextStyle(
                                            color: textColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => _eventType = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(LocaleService.tr('Thời gian:', en: 'Time:'),
                            style: TextStyle(
                                color: subTextColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        TextButton.icon(
                          onPressed: () =>
                              _selectDateTime(context, setDialogState),
                          icon: const Icon(Icons.calendar_month_rounded,
                              color: Color(0xFF10B981), size: 18),
                          label: Text(
                            '${_selectedDateTime.day.toString().padLeft(2, '0')}/${_selectedDateTime.month.toString().padLeft(2, '0')} - ${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF10B981).withOpacity(0.12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(LocaleService.tr('Hủy', en: 'Cancel'),
                        style: TextStyle(
                            color: captionColor, fontWeight: FontWeight.bold)),
                  ),
                  PremiumButton(
                    onPressed: () {
                      _createEvent();
                      Navigator.pop(context);
                    },
                    backgroundColor: const Color(0xFF10B981),
                    child: Text(LocaleService.tr('Tạo', en: 'Create'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF10B981);

    return ListenableBuilder(
      listenable: Listenable.merge(
          [ThemeService.isDarkMode, LocaleService.languageCode]),
      builder: (context, child) {
        final isDark = ThemeService.isDarkMode.value;
        final textColor = ThemeService.getTextColor(isDark);
        final subTextColor = ThemeService.getSubTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);
        final cardBgColor = ThemeService.getCardColor(isDark);
        final borderColor = ThemeService.getBorderColor(isDark);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleService.tr('LỊCH TRÌNH CÁ NHÂN',
                              en: 'PERSONAL SCHEDULE'),
                          style: TextStyle(
                              color: captionColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2),
                        ),
                        Text(
                          LocaleService.tr('Thời Gian Biểu', en: 'Timetable'),
                          style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    PremiumButton.icon(
                      onPressed: _showCreateEventDialog,
                      icon: Icons.add,
                      label: LocaleService.tr('Thêm sự kiện', en: 'Add event'),
                      backgroundColor: themeColor,
                    )
                  ],
                ),
                const SizedBox(height: 18),

                // Events List
                Expanded(
                  child: _isLoading
                      ? ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 6,
                          itemBuilder: (context, index) => const Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: ShimmerLoading(
                                width: double.infinity,
                                height: 86,
                                borderRadius: 20),
                          ),
                        )
                      : _events.isEmpty
                          ? FadeInSlide(
                              delayMs: 100,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.calendar_today_rounded,
                                        size: 54,
                                        color: captionColor.withOpacity(0.4)),
                                    const SizedBox(height: 12),
                                    Text(
                                        LocaleService.tr(
                                            'Chưa có sự kiện hay lịch trình nào.',
                                            en: 'No events or schedules yet.'),
                                        style: TextStyle(
                                            color: captionColor, fontSize: 14)),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadEvents,
                              color: themeColor,
                              child: ListView.builder(
                                itemCount: _events.length,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final event = _events[index];
                                  final eventId = event['id'];
                                  final title = event['title'] ??
                                      LocaleService.tr('Sự kiện không tên',
                                          en: 'Untitled event');
                                  final desc = event['description'] ?? '';
                                  final start = event['start'] ?? '';
                                  final type = event['type'] ?? 'reminder';
                                  final source = event['source'] ?? 'event';

                                  String formattedDate = '';
                                  try {
                                    final completedAt =
                                        DateTime.parse(start).toLocal();
                                    formattedDate =
                                        '${completedAt.hour.toString().padLeft(2, '0')}:${completedAt.minute.toString().padLeft(2, '0')} - ${completedAt.day}/${completedAt.month}';
                                  } catch (_) {}

                                  Color cardColor;
                                  IconData cardIcon;
                                  if (source == 'task') {
                                    cardColor = const Color(0xFFF43F5E);
                                    cardIcon = Icons.task_alt_rounded;
                                  } else {
                                    if (type == 'meeting') {
                                      cardColor = const Color(0xFF06B6D4);
                                      cardIcon = Icons.videocam_rounded;
                                    } else {
                                      cardColor = themeColor;
                                      cardIcon =
                                          Icons.notifications_active_rounded;
                                    }
                                  }

                                  return FadeInSlide(
                                    delayMs: index * 60,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12.0),
                                      child: GlassCard(
                                        borderRadius: 20,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 14),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    cardColor.withOpacity(0.1),
                                              ),
                                              child: Icon(cardIcon,
                                                  color: cardColor, size: 20),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: textColor),
                                                  ),
                                                  if (desc.isNotEmpty) ...[
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      desc,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: subTextColor),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .access_time_rounded,
                                                          color: captionColor,
                                                          size: 12),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        formattedDate,
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            color: captionColor,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            if (source == 'event')
                                              IconButton(
                                                icon: Icon(
                                                    Icons
                                                        .delete_outline_rounded,
                                                    color: Colors.redAccent
                                                        .withOpacity(0.8),
                                                    size: 22),
                                                onPressed: () =>
                                                    _deleteEvent(eventId),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
