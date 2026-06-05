import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sketchy_design_lang/sketchy_design_lang.dart' as sketchy;
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/locale_service.dart';
import '../widgets/premium_widgets.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  bool _isLoading = true;
  List<dynamic> _tasks = [];
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _taskPriority = 'Medium';

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      String url = 'https://prm-tan.vercel.app/api/tasks';
      List<String> queryParams = [];

      if (_selectedStatus != 'All') {
        queryParams.add('status=$_selectedStatus');
      }
      if (_searchController.text.trim().isNotEmpty) {
        queryParams.add('search=${Uri.encodeComponent(_searchController.text.trim())}');
      }
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _tasks = jsonDecode(response.body);
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

  Future<void> _createTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('https://prm-tan.vercel.app/api/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'title': title,
          'description': _descController.text.trim(),
          'priority': _taskPriority,
          'status': 'Pending'
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        _titleController.clear();
        _descController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleService.tr('Đã thêm công việc mới thành công! 📝', en: 'Task added successfully! 📝')),
              backgroundColor: const Color(0xFF8B5CF6),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        _loadTasks();
      }
    } catch (_) {}
  }

  Future<void> _toggleTaskComplete(String taskId, String currentStatus) async {
    final newStatus = currentStatus == 'Completed' ? 'Pending' : 'Completed';
    try {
      final token = await AuthService.getToken();
      final response = await http.put(
        Uri.parse('https://prm-tan.vercel.app/api/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': newStatus}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(newStatus == 'Completed'
                  ? LocaleService.tr('Tuyệt vời! Đã hoàn thành công việc! 🎉', en: 'Awesome! Task completed! 🎉')
                  : LocaleService.tr('Đã mở lại công việc.', en: 'Task reopened.')),
              backgroundColor: newStatus == 'Completed'
                  ? const Color(0xFF10B981)
                  : Colors.amber[800],
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        _loadTasks();
      }
    } catch (_) {}
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse('https://prm-tan.vercel.app/api/tasks/$taskId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleService.tr('Đã xóa công việc thành công! 🗑️', en: 'Task deleted successfully! 🗑️')),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        _loadTasks();
      }
    } catch (_) {}
  }

  void _showCreateTaskDialog() {
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
                  side: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
                ),
                title: Text(
                  LocaleService.tr('TẠO CÔNG VIỆC MỚI', en: 'CREATE NEW TASK'),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor, letterSpacing: 1.5),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PremiumInputField(
                      controller: _titleController,
                      label: LocaleService.tr('Tiêu đề công việc *', en: 'Task title *'),
                      hintText: LocaleService.tr('Nhập tiêu đề...', en: 'Enter title...'),
                      prefixIcon: Icons.title_rounded,
                    ),
                    const SizedBox(height: 14),
                    PremiumInputField(
                      controller: _descController,
                      label: LocaleService.tr('Mô tả ngắn', en: 'Short description'),
                      hintText: LocaleService.tr('Nhập mô tả chi tiết...', en: 'Enter detailed description...'),
                      prefixIcon: Icons.description_outlined,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(LocaleService.tr('Độ ưu tiên:', en: 'Priority:'), style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _taskPriority,
                              dropdownColor: dialogBg,
                              icon: Icon(Icons.keyboard_arrow_down_rounded, color: subTextColor),
                              items: <String>['Low', 'Medium', 'High'].map((String value) {
                                Color badgeColor;
                                if (value == 'High') {
                                  badgeColor = const Color(0xFFF43F5E);
                                } else if (value == 'Medium') {
                                  badgeColor = const Color(0xFFEAB308);
                                } else {
                                  badgeColor = const Color(0xFF10B981);
                                }
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(value, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setDialogState(() => _taskPriority = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(LocaleService.tr('Hủy', en: 'Cancel'), style: TextStyle(color: captionColor, fontWeight: FontWeight.bold)),
                  ),
                  PremiumButton(
                    onPressed: () {
                      _createTask();
                      Navigator.pop(context);
                    },
                    backgroundColor: const Color(0xFF8B5CF6),
                    child: Text(LocaleService.tr('Tạo', en: 'Create'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    const themeColor = Color(0xFF8B5CF6);

    return ListenableBuilder(
      listenable: Listenable.merge([ThemeService.isDarkMode, LocaleService.languageCode]),
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
                          LocaleService.tr('QUẢN LÝ TIẾN ĐỘ', en: 'PROGRESS MANAGEMENT'),
                          style: TextStyle(color: captionColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                        Text(
                          LocaleService.tr('Công Việc', en: 'Tasks'),
                          style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    PremiumButton.icon(
                      onPressed: _showCreateTaskDialog,
                      icon: Icons.add,
                      label: LocaleService.tr('Thêm task', en: 'Add task'),
                      backgroundColor: themeColor,
                    )
                  ],
                ),
                const SizedBox(height: 18),

                // Search Bar & Filter Tab
                Row(
                  children: [
                    Expanded(
                      child: ThemeService.isSketchyMode.value
                          ? sketchy.SketchyTextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: LocaleService.tr('Tìm kiếm công việc...', en: 'Search tasks...'),
                                hintStyle: TextStyle(color: captionColor, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: captionColor, size: 20),
                              ),
                              onSubmitted: (_) => _loadTasks(),
                            )
                          : Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: cardBgColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: borderColor),
                              ),
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: LocaleService.tr('Tìm kiếm công việc...', en: 'Search tasks...'),
                                  hintStyle: TextStyle(color: captionColor, fontSize: 14),
                                  prefixIcon: Icon(Icons.search, color: captionColor, size: 20),
                                  border: InputBorder.none,
                                ),
                                style: TextStyle(color: textColor),
                                onSubmitted: (_) => _loadTasks(),
                              ),
                            ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _selectedStatus,
                      dropdownColor: isDark ? const Color(0xFF0F1524) : Colors.white,
                      underline: const SizedBox(),
                      icon: Icon(Icons.filter_list_rounded, color: subTextColor),
                      items: <String>['All', 'Pending', 'In Progress', 'Completed', 'Overdue'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value == 'All' ? LocaleService.tr('Tất cả', en: 'All') : value, style: TextStyle(color: textColor, fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedStatus = val);
                          _loadTasks();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Tasks List
                Expanded(
                  child: _isLoading
                      ? ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 6,
                          itemBuilder: (context, index) => const Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: ShimmerLoading(width: double.infinity, height: 86, borderRadius: 20),
                          ),
                        )
                      : _tasks.isEmpty
                          ? FadeInSlide(
                              delayMs: 100,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.playlist_add_check_rounded, size: 54, color: captionColor.withOpacity(0.4)),
                                    const SizedBox(height: 12),
                                    Text(LocaleService.tr('Chưa có công việc nào.', en: 'No tasks yet.'), style: TextStyle(color: captionColor, fontSize: 14)),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadTasks,
                              color: themeColor,
                              child: ListView.builder(
                                itemCount: _tasks.length,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final task = _tasks[index];
                                  final taskId = task['_id'];
                                  final title = task['title'] ?? LocaleService.tr('Công việc không tên', en: 'Untitled task');
                                  final desc = task['description'] ?? '';
                                  final status = task['status'] ?? 'Pending';
                                  final priority = task['priority'] ?? 'Medium';

                                  Color priorityColor;
                                  if (priority == 'High') {
                                    priorityColor = const Color(0xFFF43F5E);
                                  } else if (priority == 'Medium') {
                                    priorityColor = const Color(0xFFEAB308);
                                  } else {
                                    priorityColor = const Color(0xFF10B981);
                                  }

                                  return FadeInSlide(
                                    delayMs: index * 60,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: GlassCard(
                                        borderRadius: 20,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        child: Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _toggleTaskComplete(taskId, status),
                                              child: Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: status == 'Completed' ? const Color(0xFF10B981) : (isDark ? Colors.white24 : Colors.black26),
                                                    width: 2,
                                                  ),
                                                  color: status == 'Completed'
                                                      ? const Color(0xFF10B981).withOpacity(0.1)
                                                      : Colors.transparent,
                                                ),
                                                child: status == 'Completed'
                                                    ? const Icon(Icons.check, size: 14, color: Color(0xFF10B981))
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    title,
                                                    style: TextStyle(
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                      color: textColor,
                                                      decoration: status == 'Completed'
                                                          ? TextDecoration.lineThrough
                                                          : null,
                                                    ),
                                                  ),
                                                  if (desc.isNotEmpty) ...[
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      desc,
                                                      style: TextStyle(fontSize: 12, color: subTextColor),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: priorityColor.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          priority.toUpperCase(),
                                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: priorityColor),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        status.toUpperCase(),
                                                        style: TextStyle(
                                                          fontSize: 9,
                                                          fontWeight: FontWeight.bold,
                                                          color: status == 'Completed'
                                                              ? const Color(0xFF10B981)
                                                              : captionColor,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete_outline_rounded, color: Colors.redAccent.withOpacity(0.8), size: 22),
                                              onPressed: () => _deleteTask(taskId),
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
