import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/theme_service.dart';
import '../widgets/premium_widgets.dart';

enum CalendarFilter { all, events, tasks, project, overdue }

enum CalendarItemKind { event, personalTask, projectTask, deadline }

class CalendarItem {
  final String id;
  final String title;
  final String description;
  final DateTime start;
  final DateTime? end;
  final CalendarItemKind kind;
  final String source;
  final String sourceType;
  final String? projectName;
  final String? status;
  final String? priority;
  final bool hasReminder;

  const CalendarItem({
    required this.id,
    required this.title,
    required this.description,
    required this.start,
    required this.kind,
    required this.source,
    required this.sourceType,
    this.end,
    this.projectName,
    this.status,
    this.priority,
    this.hasReminder = false,
  });

  bool get isTask => source == 'task';

  bool get isCompleted => status?.toLowerCase() == 'completed';

  bool get isOverdue {
    final today = _dateOnly(DateTime.now());
    return isTask && !isCompleted && _dateOnly(start).isBefore(today);
  }

  bool get isAllDay => start.hour == 0 && start.minute == 0;

  Color get accentColor {
    if (isOverdue || kind == CalendarItemKind.deadline) {
      return const Color(0xFFEF4444);
    }
    switch (kind) {
      case CalendarItemKind.event:
        return const Color(0xFF10B981);
      case CalendarItemKind.personalTask:
        return const Color(0xFF06B6D4);
      case CalendarItemKind.projectTask:
        return const Color(0xFF8B5CF6);
      case CalendarItemKind.deadline:
        return const Color(0xFFEF4444);
    }
  }

  String get typeLabel {
    if (isOverdue) return 'Overdue';
    switch (kind) {
      case CalendarItemKind.event:
        return 'Event';
      case CalendarItemKind.personalTask:
        return 'Personal Task';
      case CalendarItemKind.projectTask:
        return 'Project Task';
      case CalendarItemKind.deadline:
        return 'Deadline';
    }
  }
}

class DateIndicatorCounts {
  final int events;
  final int personalTasks;
  final int projectTasks;
  final int deadlines;

  const DateIndicatorCounts({
    this.events = 0,
    this.personalTasks = 0,
    this.projectTasks = 0,
    this.deadlines = 0,
  });

  bool get hasAny =>
      events > 0 || personalTasks > 0 || projectTasks > 0 || deadlines > 0;
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const Color _accent = Color(0xFF06B6D4);
  static const Color _eventColor = Color(0xFF10B981);

  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  int _loadRequestId = 0;
  List<CalendarItem> _items = [];
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = _dateOnly(DateTime.now());
  CalendarFilter _selectedFilter = CalendarFilter.all;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _eventType = 'meeting';
  String _taskPriority = 'Medium';
  String _reminderType = 'none';
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));

  @override
  void initState() {
    super.initState();
    _loadCalendarItems();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadCalendarItems() async {
    if (!mounted) return;
    final requestId = ++_loadRequestId;
    setState(() => _isLoading = true);

    final gridStart = _calendarGridStart(_focusedMonth);
    final gridEnd = _calendarGridEnd(_focusedMonth);

    try {
      final token = await AuthService.getToken();
      final uri = Uri.parse('${AuthService.apiBaseUrl}/calendar/events')
          .replace(queryParameters: {
        'start': gridStart.toUtc().toIso8601String(),
        'end': gridEnd
            .add(const Duration(hours: 23, minutes: 59, seconds: 59))
            .toUtc()
            .toIso8601String(),
      });

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) throw Exception(response.body);

      final rawItems = jsonDecode(response.body) as List<dynamic>;
      final mappedItems = rawItems
          .whereType<Map<String, dynamic>>()
          .map(_mapCalendarPayload)
          .whereType<CalendarItem>()
          .toList();

      if (mounted && requestId == _loadRequestId) {
        setState(() {
          _items = sortCalendarItemsByTime(mappedItems);
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      }
    } catch (_) {
      if (mounted && requestId == _loadRequestId) {
        setState(() {
          _isLoading = false;
          _hasLoadedOnce = true;
        });
      }
    }
  }

  CalendarItem? _mapCalendarPayload(Map<String, dynamic> payload) {
    final start = _parseDate(payload['start']);
    if (start == null) return null;

    final source = payload['source']?.toString() ?? 'event';
    final sourceType = payload['sourceType']?.toString() ??
        (source == 'task' ? 'personal' : 'schedule');
    final status = payload['status']?.toString();
    final isTask = source == 'task';
    final isProjectTask = isTask && sourceType == 'project';
    final cleanTitle =
        (payload['title']?.toString() ?? 'Untitled').replaceFirst(
      RegExp(r'^\[TASK DEADLINE\]\s*'),
      '',
    );

    CalendarItemKind kind;
    if (!isTask) {
      kind = CalendarItemKind.event;
    } else if (isProjectTask) {
      kind = CalendarItemKind.projectTask;
    } else {
      kind = CalendarItemKind.personalTask;
    }

    final item = CalendarItem(
      id: payload['id']?.toString() ?? '',
      title: cleanTitle,
      description: payload['description']?.toString() ?? '',
      start: start.toLocal(),
      end: _parseDate(payload['end'])?.toLocal(),
      kind: kind,
      source: source,
      sourceType: sourceType,
      projectName: payload['projectName']?.toString(),
      status: status,
      priority: payload['priority']?.toString(),
      hasReminder: payload['notificationEnabled'] == true ||
          (payload['reminderType'] != null &&
              payload['reminderType'].toString() != 'none'),
    );

    if (item.isOverdue) {
      return CalendarItem(
        id: item.id,
        title: item.title,
        description: item.description,
        start: item.start,
        end: item.end,
        kind: CalendarItemKind.deadline,
        source: item.source,
        sourceType: item.sourceType,
        projectName: item.projectName,
        status: item.status,
        priority: item.priority,
        hasReminder: item.hasReminder,
      );
    }

    return item;
  }

  Future<void> _selectDateTime(
    BuildContext context,
    StateSetter setDialogState,
  ) async {
    final now = DateTime.now();
    final initialDate =
        _selectedDateTime.isBefore(now) ? now : _selectedDateTime;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2100),
      builder: _pickerThemeBuilder,
    );
    if (pickedDate == null || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      builder: _pickerThemeBuilder,
    );
    if (pickedTime == null) return;

    final candidate = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (candidate.isBefore(DateTime.now())) {
      _showSnack('Please choose a future time.', Colors.amber.shade800);
      return;
    }

    setDialogState(() => _selectedDateTime = candidate);
  }

  Widget _pickerThemeBuilder(BuildContext context, Widget? child) {
    final isDark = ThemeService.isDarkMode.value;
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: isDark
            ? const ColorScheme.dark(
                primary: _accent,
                onPrimary: Colors.white,
                surface: Color(0xFF1E293B),
                onSurface: Colors.white,
              )
            : const ColorScheme.light(
                primary: _accent,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: Colors.black,
              ),
      ),
      child: child!,
    );
  }

  Future<void> _createEvent({String forcedType = 'meeting'}) async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    if (_selectedDateTime.isBefore(DateTime.now())) {
      _showSnack('Please choose a future time.', Colors.amber.shade800);
      return;
    }

    try {
      final token = await AuthService.getToken();
      final response = await http
          .post(
            Uri.parse('${AuthService.apiBaseUrl}/calendar/events'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'title': title,
              'description': _descController.text.trim(),
              'startTime': _selectedDateTime.toUtc().toIso8601String(),
              'endTime': _selectedDateTime
                  .add(const Duration(hours: 1))
                  .toUtc()
                  .toIso8601String(),
              'type': forcedType == 'reminder' ? 'reminder' : _eventType,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 201) throw Exception(response.body);

      _clearForm();
      if (mounted) {
        Navigator.pop(context);
        _showSnack(
          forcedType == 'reminder' ? 'Reminder added' : 'Event added',
          _eventColor,
        );
      }
      _loadCalendarItems();
    } catch (_) {
      if (mounted) _showSnack('Could not create item', Colors.redAccent);
    }
  }

  Future<void> _createPersonalTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    if (_selectedDateTime.isBefore(DateTime.now())) {
      _showSnack('Please choose a future due time.', Colors.amber.shade800);
      return;
    }

    try {
      final token = await AuthService.getToken();
      final response = await http
          .post(
            Uri.parse('${AuthService.apiBaseUrl}/tasks'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'title': title,
              'description': _descController.text.trim(),
              'status': 'Pending',
              'priority': _taskPriority,
              'dueDate': _selectedDateTime.toUtc().toIso8601String(),
              'deadline': _selectedDateTime.toUtc().toIso8601String(),
              'dueTime':
                  '${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
              'reminderType': _reminderType,
              'notificationEnabled': _reminderType != 'none',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 201) throw Exception(response.body);

      _clearForm();
      if (mounted) {
        Navigator.pop(context);
        _showSnack('Personal task added', _accent);
      }
      _loadCalendarItems();
    } catch (_) {
      if (mounted) _showSnack('Could not create task', Colors.redAccent);
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse('${AuthService.apiBaseUrl}/calendar/events/$eventId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) throw Exception(response.body);
      _showSnack('Event deleted successfully', Colors.redAccent);
      _loadCalendarItems();
    } catch (_) {
      if (mounted) _showSnack('Could not delete event', Colors.redAccent);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _descController.clear();
    _eventType = 'meeting';
    _taskPriority = 'Medium';
    _reminderType = 'none';
    _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openAddItemSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = ThemeService.isDarkMode.value;
        final sheetColor = ThemeService.getDialogBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);
        final subTextColor = ThemeService.getSubTextColor(isDark);
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 26),
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: subTextColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Add to calendar',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _AddSheetAction(
                icon: Icons.event_rounded,
                color: _eventColor,
                title: 'Add Event',
                subtitle: 'Create a scheduled event with a start time.',
                onTap: () {
                  Navigator.pop(context);
                  _showItemDialog(CalendarItemKind.event);
                },
              ),
              _AddSheetAction(
                icon: Icons.task_alt_rounded,
                color: _accent,
                title: 'Add Personal Task',
                subtitle: 'Create one shared task record with a due time.',
                onTap: () {
                  Navigator.pop(context);
                  _showItemDialog(CalendarItemKind.personalTask);
                },
              ),
              _AddSheetAction(
                icon: Icons.notifications_active_rounded,
                color: const Color(0xFFF59E0B),
                title: 'Add Reminder',
                subtitle: 'Create a reminder event on your schedule.',
                onTap: () {
                  Navigator.pop(context);
                  _showItemDialog(CalendarItemKind.deadline);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showItemDialog(CalendarItemKind createKind) {
    _clearForm();
    _selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      DateTime.now().hour + 1,
    );
    if (_selectedDateTime.isBefore(DateTime.now())) {
      _selectedDateTime = DateTime.now().add(const Duration(hours: 1));
    }

    final isTask = createKind == CalendarItemKind.personalTask;
    final isReminder = createKind == CalendarItemKind.deadline;
    final title = isTask
        ? 'Add Personal Task'
        : isReminder
            ? 'Add Reminder'
            : 'Add Event';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = ThemeService.isDarkMode.value;
            final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
            final textColor = ThemeService.getTextColor(isDark);
            final captionColor = ThemeService.getCaptionColor(isDark);

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: AlertDialog(
                backgroundColor: dialogBg.withValues(alpha: 0.94),
                insetPadding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                title: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PremiumInputField(
                        controller: _titleController,
                        label: isTask ? 'Task title *' : 'Title *',
                        hintText: isTask ? 'Enter task title' : 'Enter title',
                        prefixIcon:
                            isTask ? Icons.task_alt_rounded : Icons.title,
                      ),
                      const SizedBox(height: 14),
                      PremiumInputField(
                        controller: _descController,
                        label: 'Description',
                        hintText: 'Add details',
                        prefixIcon: Icons.description_outlined,
                      ),
                      const SizedBox(height: 16),
                      if (!isTask)
                        _RoundedDropdown<String>(
                          label: 'Type',
                          value: isReminder ? 'reminder' : _eventType,
                          items: const ['meeting', 'reminder', 'other'],
                          itemLabel: (value) => value == 'meeting'
                              ? 'Meeting'
                              : value == 'reminder'
                                  ? 'Reminder'
                                  : 'Other',
                          enabled: !isReminder,
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => _eventType = value);
                            }
                          },
                        ),
                      if (isTask) ...[
                        _RoundedDropdown<String>(
                          label: 'Priority',
                          value: _taskPriority,
                          items: const ['Low', 'Medium', 'High', 'Urgent'],
                          itemLabel: (value) => value,
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => _taskPriority = value);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        _RoundedDropdown<String>(
                          label: 'Reminder',
                          value: _reminderType,
                          items: const [
                            'none',
                            'at_time',
                            '15_min_before',
                            '30_min_before',
                            '1_hour_before',
                            '1_day_before',
                          ],
                          itemLabel: _reminderLabel,
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => _reminderType = value);
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 14),
                      _DateTimeSelector(
                        value: _selectedDateTime,
                        label: isTask ? 'Due date and time' : 'Date and time',
                        onTap: () => _selectDateTime(context, setDialogState),
                      ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: captionColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  PremiumButton(
                    onPressed: () {
                      if (isTask) {
                        _createPersonalTask();
                      } else {
                        _createEvent(forcedType: isReminder ? 'reminder' : '');
                      }
                    },
                    backgroundColor: isReminder
                        ? const Color(0xFFF59E0B)
                        : isTask
                            ? _accent
                            : _eventColor,
                    child: Text(
                      isTask ? 'Add task' : 'Create',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openItemDetail(CalendarItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = ThemeService.isDarkMode.value;
        final sheetColor = ThemeService.getDialogBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);
        final subTextColor = ThemeService.getSubTextColor(isDark);
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 26),
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: subTextColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _TypeIcon(item: item, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.typeLabel} · ${_formatDateTime(item.start)}',
                          style: TextStyle(color: subTextColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  item.description,
                  style: TextStyle(color: subTextColor, height: 1.4),
                ),
              ],
              if (item.projectName?.isNotEmpty == true) ...[
                const SizedBox(height: 14),
                _InfoPill(
                  icon: Icons.folder_rounded,
                  text: item.projectName!,
                  color: const Color(0xFF8B5CF6),
                ),
              ],
              const SizedBox(height: 18),
              if (item.source == 'event')
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteEvent(item.id);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Delete event'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _moveMonth(int delta) {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + delta);
      final today = _dateOnly(DateTime.now());
      if (_focusedMonth.year == today.year &&
          _focusedMonth.month == today.month) {
        _selectedDate = today;
      } else {
        _selectedDate = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
      }
    });
    _loadCalendarItems();
  }

  List<CalendarItem> get _filteredItems =>
      filterCalendarItems(_items, _selectedFilter);

  List<CalendarItem> get _selectedDayItems =>
      getCalendarItemsForDate(_selectedDate, _filteredItems);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
        [ThemeService.isDarkMode, LocaleService.languageCode],
      ),
      builder: (context, child) {
        final isDark = ThemeService.isDarkMode.value;
        final textColor = ThemeService.getTextColor(isDark);
        final subTextColor = ThemeService.getSubTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            top: false,
            child: RefreshIndicator(
              onRefresh: _loadCalendarItems,
              color: _accent,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: CalendarHeader(
                        textColor: textColor,
                        captionColor: captionColor,
                        onAddPressed: _openAddItemSheet,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: CalendarFilterTabs(
                        selectedFilter: _selectedFilter,
                        onChanged: (filter) =>
                            setState(() => _selectedFilter = filter),
                      ),
                    ),
                  ),
                  if (_isLoading && _hasLoadedOnce)
                    const SliverPadding(
                      padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
                      sliver: SliverToBoxAdapter(
                        child: LinearProgressIndicator(
                          minHeight: 3,
                          color: _accent,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: _isLoading && !_hasLoadedOnce
                          ? const ShimmerLoading(
                              width: double.infinity,
                              height: 380,
                              borderRadius: 24,
                            )
                          : MonthCalendarCard(
                              focusedMonth: _focusedMonth,
                              selectedDate: _selectedDate,
                              items: _filteredItems,
                              textColor: textColor,
                              subTextColor: subTextColor,
                              captionColor: captionColor,
                              onPrevious: () => _moveMonth(-1),
                              onNext: () => _moveMonth(1),
                              onSelectDate: (date) {
                                setState(() => _selectedDate = _dateOnly(date));
                              },
                            ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    sliver: SliverToBoxAdapter(
                      child: _isLoading && !_hasLoadedOnce
                          ? const _AgendaSkeleton()
                          : AgendaSection(
                              selectedDate: _selectedDate,
                              items: _selectedDayItems,
                              textColor: textColor,
                              subTextColor: subTextColor,
                              captionColor: captionColor,
                              onTapItem: _openItemDetail,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CalendarHeader extends StatelessWidget {
  final Color textColor;
  final Color captionColor;
  final VoidCallback onAddPressed;

  const CalendarHeader({
    super.key,
    required this.textColor,
    required this.captionColor,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PERSONAL SCHEDULE',
                style: TextStyle(
                  color: captionColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Calendar',
                style: TextStyle(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        PremiumButton.icon(
          onPressed: onAddPressed,
          icon: Icons.add_rounded,
          label: 'New',
          backgroundColor: const Color(0xFF06B6D4),
        ),
      ],
    );
  }
}

class CalendarFilterTabs extends StatelessWidget {
  final CalendarFilter selectedFilter;
  final ValueChanged<CalendarFilter> onChanged;

  const CalendarFilterTabs({
    super.key,
    required this.selectedFilter,
    required this.onChanged,
  });

  static const _labels = {
    CalendarFilter.all: 'All',
    CalendarFilter.events: 'Events',
    CalendarFilter.tasks: 'Tasks',
    CalendarFilter.project: 'Project',
    CalendarFilter.overdue: 'Overdue',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: CalendarFilter.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = CalendarFilter.values[index];
          final selected = filter == selectedFilter;
          return GestureDetector(
            onTap: () => onChanged(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF06B6D4).withValues(alpha: 0.16)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.035)
                        : Colors.white.withValues(alpha: 0.72)),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF06B6D4)
                      : captionColor.withValues(alpha: 0.14),
                ),
              ),
              child: Text(
                _labels[filter]!,
                style: TextStyle(
                  color: selected ? const Color(0xFF06B6D4) : textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class MonthCalendarCard extends StatelessWidget {
  final DateTime focusedMonth;
  final DateTime selectedDate;
  final List<CalendarItem> items;
  final Color textColor;
  final Color subTextColor;
  final Color captionColor;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelectDate;

  const MonthCalendarCard({
    super.key,
    required this.focusedMonth,
    required this.selectedDate,
    required this.items,
    required this.textColor,
    required this.subTextColor,
    required this.captionColor,
    required this.onPrevious,
    required this.onNext,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    final days = _visibleCalendarDays(focusedMonth);

    return GlassCard(
      borderRadius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatMonthTitle(focusedMonth),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _MonthButton(icon: Icons.chevron_left, onTap: onPrevious),
              const SizedBox(width: 8),
              _MonthButton(icon: Icons.chevron_right, onTap: onNext),
            ],
          ),
          const SizedBox(height: 16),
          WeekdayRow(captionColor: captionColor),
          const SizedBox(height: 8),
          GridView.builder(
            itemCount: days.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.86,
              mainAxisSpacing: 6,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              return DayCell(
                date: day,
                isCurrentMonth: day.month == focusedMonth.month,
                isSelected: _isSameDay(day, selectedDate),
                isToday: _isSameDay(day, DateTime.now()),
                counts: getDateIndicatorCounts(day, items),
                textColor: textColor,
                captionColor: captionColor,
                onTap: () => onSelectDate(day),
              );
            },
          ),
          const SizedBox(height: 14),
          const CalendarLegend(),
        ],
      ),
    );
  }
}

class WeekdayRow extends StatelessWidget {
  final Color captionColor;

  const WeekdayRow({super.key, required this.captionColor});

  @override
  Widget build(BuildContext context) {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: captionColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class DayCell extends StatelessWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final bool isSelected;
  final bool isToday;
  final DateIndicatorCounts counts;
  final Color textColor;
  final Color captionColor;
  final VoidCallback onTap;

  const DayCell({
    super.key,
    required this.date,
    required this.isCurrentMonth,
    required this.isSelected,
    required this.isToday,
    required this.counts,
    required this.textColor,
    required this.captionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isCurrentMonth ? textColor : captionColor.withValues(alpha: 0.45);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF06B6D4).withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF06B6D4)
                : isToday
                    ? const Color(0xFF06B6D4).withValues(alpha: 0.42)
                    : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: isSelected ? const Color(0xFF06B6D4) : color,
                fontSize: 13,
                fontWeight:
                    isSelected || isToday ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            _DotRow(counts: counts),
          ],
        ),
      ),
    );
  }
}

class CalendarLegend extends StatelessWidget {
  const CalendarLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _LegendItem(color: Color(0xFF10B981), label: 'Events'),
        _LegendItem(color: Color(0xFF06B6D4), label: 'Tasks'),
        _LegendItem(color: Color(0xFF8B5CF6), label: 'Project Tasks'),
        _LegendItem(color: Color(0xFFEF4444), label: 'Deadlines'),
      ],
    );
  }
}

class AgendaSection extends StatelessWidget {
  final DateTime selectedDate;
  final List<CalendarItem> items;
  final Color textColor;
  final Color subTextColor;
  final Color captionColor;
  final ValueChanged<CalendarItem> onTapItem;

  const AgendaSection({
    super.key,
    required this.selectedDate,
    required this.items,
    required this.textColor,
    required this.subTextColor,
    required this.captionColor,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    final grouped = groupCalendarItemsByTime(items);
    final allDay = grouped['All-day'] ?? [];
    final timedEntries = grouped.entries
        .where((entry) => entry.key != 'All-day')
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _agendaTitle(selectedDate),
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '${items.length} items',
              style: TextStyle(
                color: captionColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _CalendarEmptyState(captionColor: captionColor, textColor: textColor)
        else ...[
          if (allDay.isNotEmpty)
            _AgendaGroup(
              label: 'All-day',
              items: allDay,
              textColor: textColor,
              subTextColor: subTextColor,
              onTapItem: onTapItem,
            ),
          for (final entry in timedEntries)
            _AgendaGroup(
              label: entry.key,
              items: entry.value,
              textColor: textColor,
              subTextColor: subTextColor,
              onTapItem: onTapItem,
            ),
        ],
      ],
    );
  }
}

class AgendaItemCard extends StatelessWidget {
  final CalendarItem item;
  final Color textColor;
  final Color subTextColor;
  final VoidCallback onTap;

  const AgendaItemCard({
    super.key,
    required this.item,
    required this.textColor,
    required this.subTextColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 18,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 58,
              decoration: BoxDecoration(
                color: item.accentColor,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 12),
            _TypeIcon(item: item),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (item.hasReminder)
                        Icon(
                          Icons.notifications_active_rounded,
                          size: 14,
                          color: item.accentColor,
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _secondaryLine(item),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _InfoPill(
                        icon: Icons.label_rounded,
                        text: item.typeLabel,
                        color: item.accentColor,
                      ),
                      if (item.status?.isNotEmpty == true)
                        _InfoPill(
                          icon: Icons.flag_rounded,
                          text: item.status!,
                          color: item.accentColor,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: subTextColor.withValues(alpha: 0.65),
            ),
          ],
        ),
      ),
    );
  }
}

List<CalendarItem> getCalendarItemsForDate(
  DateTime date,
  List<CalendarItem> items,
) {
  return sortCalendarItemsByTime(
    items.where((item) => _isSameDay(item.start, date)).toList(),
  );
}

List<CalendarItem> mapTasksToCalendarItems(List<dynamic> tasks) {
  return tasks
      .whereType<Map<String, dynamic>>()
      .map((task) {
        final start = _parseDate(task['deadline'] ?? task['dueDate']);
        if (start == null) return null;
        final sourceType = task['sourceType']?.toString() ?? 'personal';
        return CalendarItem(
          id: task['_id']?.toString() ?? task['id']?.toString() ?? '',
          title: task['title']?.toString() ?? 'Untitled task',
          description: task['description']?.toString() ?? '',
          start: start.toLocal(),
          kind: sourceType == 'project'
              ? CalendarItemKind.projectTask
              : CalendarItemKind.personalTask,
          source: 'task',
          sourceType: sourceType,
          projectName: task['projectName']?.toString(),
          status: task['status']?.toString(),
          priority: task['priority']?.toString(),
          hasReminder: task['notificationEnabled'] == true,
        );
      })
      .whereType<CalendarItem>()
      .toList();
}

List<CalendarItem> mapEventsToCalendarItems(List<dynamic> events) {
  return events
      .whereType<Map<String, dynamic>>()
      .map((event) {
        final start = _parseDate(event['start'] ?? event['startTime']);
        if (start == null) return null;
        return CalendarItem(
          id: event['id']?.toString() ?? event['_id']?.toString() ?? '',
          title: event['title']?.toString() ?? 'Untitled event',
          description: event['description']?.toString() ?? '',
          start: start.toLocal(),
          end: _parseDate(event['end'] ?? event['endTime'])?.toLocal(),
          kind: CalendarItemKind.event,
          source: 'event',
          sourceType: 'schedule',
          hasReminder: event['type']?.toString() == 'reminder',
        );
      })
      .whereType<CalendarItem>()
      .toList();
}

Map<String, List<CalendarItem>> groupCalendarItemsByTime(
  List<CalendarItem> items,
) {
  final grouped = <String, List<CalendarItem>>{};
  for (final item in items) {
    final key = item.isAllDay ? 'All-day' : _formatTime(item.start);
    grouped.putIfAbsent(key, () => []).add(item);
  }
  return grouped;
}

DateIndicatorCounts getDateIndicatorCounts(
  DateTime date,
  List<CalendarItem> items,
) {
  int events = 0;
  int personalTasks = 0;
  int projectTasks = 0;
  int deadlines = 0;

  for (final item in items) {
    if (!_isSameDay(item.start, date)) continue;
    if (item.isOverdue || item.kind == CalendarItemKind.deadline) {
      deadlines++;
    } else if (item.kind == CalendarItemKind.event) {
      events++;
    } else if (item.kind == CalendarItemKind.projectTask) {
      projectTasks++;
    } else {
      personalTasks++;
    }
  }

  return DateIndicatorCounts(
    events: events,
    personalTasks: personalTasks,
    projectTasks: projectTasks,
    deadlines: deadlines,
  );
}

List<CalendarItem> filterCalendarItems(
  List<CalendarItem> items,
  CalendarFilter filter,
) {
  switch (filter) {
    case CalendarFilter.all:
      return items;
    case CalendarFilter.events:
      return items
          .where((item) => item.kind == CalendarItemKind.event)
          .toList();
    case CalendarFilter.tasks:
      return items.where((item) => item.isTask).toList();
    case CalendarFilter.project:
      return items
          .where((item) => item.kind == CalendarItemKind.projectTask)
          .toList();
    case CalendarFilter.overdue:
      return items.where((item) => item.isOverdue).toList();
  }
}

List<CalendarItem> sortCalendarItemsByTime(List<CalendarItem> items) {
  final sorted = [...items];
  sorted.sort((a, b) {
    if (a.isAllDay != b.isAllDay) return a.isAllDay ? -1 : 1;
    return a.start.compareTo(b.start);
  });
  return sorted;
}

class _AgendaGroup extends StatelessWidget {
  final String label;
  final List<CalendarItem> items;
  final Color textColor;
  final Color subTextColor;
  final ValueChanged<CalendarItem> onTapItem;

  const _AgendaGroup({
    required this.label,
    required this.items,
    required this.textColor,
    required this.subTextColor,
    required this.onTapItem,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                color: subTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AgendaItemCard(
                item: item,
                textColor: textColor,
                subTextColor: subTextColor,
                onTap: () => onTapItem(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSheetAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddSheetAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: subTextColor, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: subTextColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeSelector extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  const _DateTimeSelector({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: Color(0xFF06B6D4)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(color: subTextColor, fontSize: 11)),
                  const SizedBox(height: 3),
                  Text(
                    _formatDateTime(value),
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: subTextColor),
          ],
        ),
      ),
    );
  }
}

class _RoundedDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  const _RoundedDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: subTextColor.withValues(alpha: 0.12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: dialogBg,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: subTextColor),
          onChanged: enabled ? onChanged : null,
          items: items
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(color: subTextColor, fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        itemLabel(item),
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  final CalendarItem item;
  final double size;

  const _TypeIcon({required this.item, this.size = 40});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    if (item.isOverdue || item.kind == CalendarItemKind.deadline) {
      icon = Icons.warning_amber_rounded;
    } else if (item.kind == CalendarItemKind.event) {
      icon = Icons.event_rounded;
    } else if (item.kind == CalendarItemKind.projectTask) {
      icon = Icons.folder_rounded;
    } else {
      icon = Icons.task_alt_rounded;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: item.accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
      child: Icon(icon, color: item.accentColor, size: size * 0.5),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DotRow extends StatelessWidget {
  final DateIndicatorCounts counts;

  const _DotRow({required this.counts});

  @override
  Widget build(BuildContext context) {
    if (!counts.hasAny) return const SizedBox(height: 5);
    final dots = <Color>[
      if (counts.events > 0) const Color(0xFF10B981),
      if (counts.personalTasks > 0) const Color(0xFF06B6D4),
      if (counts.projectTasks > 0) const Color(0xFF8B5CF6),
      if (counts.deadlines > 0) const Color(0xFFEF4444),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: dots
          .take(4)
          .map(
            (color) => Container(
              width: 5,
              height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          )
          .toList(),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final subTextColor = ThemeService.getSubTextColor(isDark);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: subTextColor,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MonthButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _MonthButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.035),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: const Color(0xFF06B6D4)),
      ),
    );
  }
}

class _CalendarEmptyState extends StatelessWidget {
  final Color captionColor;
  final Color textColor;

  const _CalendarEmptyState({
    required this.captionColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 22,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 44,
              color: captionColor.withValues(alpha: 0.55),
            ),
            const SizedBox(height: 12),
            Text(
              'No events or tasks for this day',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your scheduled events and tasks with deadlines will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: captionColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaSkeleton extends StatelessWidget {
  const _AgendaSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ShimmerLoading(width: double.infinity, height: 86, borderRadius: 18),
        SizedBox(height: 12),
        ShimmerLoading(width: double.infinity, height: 86, borderRadius: 18),
      ],
    );
  }
}

DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _calendarGridStart(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  return first.subtract(Duration(days: first.weekday % 7));
}

DateTime _calendarGridEnd(DateTime month) {
  final last = DateTime(month.year, month.month + 1, 0);
  return last.add(Duration(days: 6 - (last.weekday % 7)));
}

List<DateTime> _visibleCalendarDays(DateTime month) {
  final start = _calendarGridStart(month);
  return List.generate(42, (index) => start.add(Duration(days: index)));
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String _formatMonthTitle(DateTime date) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[date.month - 1]} ${date.year}';
}

String _agendaTitle(DateTime date) {
  final today = _dateOnly(DateTime.now());
  final tomorrow = today.add(const Duration(days: 1));
  if (_isSameDay(date, today)) return 'Today, ${_formatShortDate(date)}';
  if (_isSameDay(date, tomorrow)) return 'Tomorrow, ${_formatShortDate(date)}';
  return _formatShortDate(date);
}

String _formatShortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String _formatDateTime(DateTime date) =>
    '${_formatShortDate(date)}, ${_formatTime(date)}';

String _formatTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

String _secondaryLine(CalendarItem item) {
  if (item.isOverdue) {
    final days =
        _dateOnly(DateTime.now()).difference(_dateOnly(item.start)).inDays;
    return 'Overdue by $days ${days == 1 ? 'day' : 'days'}';
  }
  if (item.projectName?.isNotEmpty == true) {
    return '${item.projectName} · ${_formatTime(item.start)}';
  }
  if (item.kind == CalendarItemKind.event && item.end != null) {
    return '${_formatTime(item.start)} - ${_formatTime(item.end!)}';
  }
  return item.isAllDay
      ? 'No specific time'
      : 'Due at ${_formatTime(item.start)}';
}

String _reminderLabel(String value) {
  switch (value) {
    case 'at_time':
      return 'At due time';
    case '15_min_before':
      return '15 min before';
    case '30_min_before':
      return '30 min before';
    case '1_hour_before':
      return '1 hour before';
    case '1_day_before':
      return '1 day before';
    default:
      return 'No reminder';
  }
}
