import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../features/calendar/models/calendar_item.dart';
import '../../../features/calendar/services/calendar_service.dart';
import '../../../features/calendar/utils/calendar_utils.dart';
import '../../../features/calendar/widgets/calendar_widgets.dart';
import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../../../core/widgets/premium_widgets.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const Color _accent = Color(0xFF06B6D4);
  static const Color _eventColor = Color(0xFF10B981);

  final CalendarService _calendarService = const CalendarService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  bool _isLoading = true;
  bool _hasLoadedOnce = false;
  int _loadRequestId = 0;
  List<CalendarItem> _items = [];
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = dateOnly(DateTime.now());
  CalendarFilter _selectedFilter = CalendarFilter.all;
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

    try {
      final gridStart = calendarGridStart(_focusedMonth);
      final gridEnd = calendarGridEnd(_focusedMonth)
          .add(const Duration(hours: 23, minutes: 59, seconds: 59));
      final items = await _calendarService.fetchCalendarItems(
        start: gridStart,
        end: gridEnd,
      );

      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _items = items;
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    } catch (_) {
      if (!mounted || requestId != _loadRequestId) return;
      setState(() {
        _isLoading = false;
        _hasLoadedOnce = true;
      });
    }
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
      await _calendarService.createEvent(
        title: title,
        description: _descController.text.trim(),
        startTime: _selectedDateTime,
        type: forcedType == 'reminder' ? 'reminder' : _eventType,
      );

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
      await _calendarService.createPersonalTask(
        title: title,
        description: _descController.text.trim(),
        priority: _taskPriority,
        dueDateTime: _selectedDateTime,
        reminderType: _reminderType,
      );

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
      await _calendarService.deleteEvent(eventId);
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
              CalendarAddSheetAction(
                icon: Icons.event_rounded,
                color: _eventColor,
                title: 'Add Event',
                subtitle: 'Create a scheduled event with a start time.',
                onTap: () {
                  Navigator.pop(context);
                  _showItemDialog(CalendarItemKind.event);
                },
              ),
              CalendarAddSheetAction(
                icon: Icons.task_alt_rounded,
                color: _accent,
                title: 'Add Personal Task',
                subtitle: 'Create one shared task record with a due time.',
                onTap: () {
                  Navigator.pop(context);
                  _showItemDialog(CalendarItemKind.personalTask);
                },
              ),
              CalendarAddSheetAction(
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
                        CalendarRoundedDropdown<String>(
                          label: 'Type',
                          value: isReminder ? 'reminder' : _eventType,
                          items: const ['meeting', 'reminder', 'other'],
                          itemLabel: _eventTypeLabel,
                          enabled: !isReminder,
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => _eventType = value);
                            }
                          },
                        ),
                      if (isTask) ...[
                        CalendarRoundedDropdown<String>(
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
                        CalendarRoundedDropdown<String>(
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
                          itemLabel: reminderLabel,
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => _reminderType = value);
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 14),
                      CalendarDateTimeSelector(
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
                  CalendarTypeIcon(item: item, size: 42),
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
                          '${item.typeLabel} - ${formatDateTime(item.start)}',
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
                CalendarInfoPill(
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
      final today = dateOnly(DateTime.now());
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
                              captionColor: captionColor,
                              onPrevious: () => _moveMonth(-1),
                              onNext: () => _moveMonth(1),
                              onSelectDate: (date) {
                                setState(() => _selectedDate = dateOnly(date));
                              },
                            ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    sliver: SliverToBoxAdapter(
                      child: _isLoading && !_hasLoadedOnce
                          ? const AgendaSkeleton()
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

String _eventTypeLabel(String value) {
  if (value == 'meeting') return 'Meeting';
  if (value == 'reminder') return 'Reminder';
  return 'Other';
}
