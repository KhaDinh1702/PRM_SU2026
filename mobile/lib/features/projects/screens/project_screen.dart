library project_screen;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/theme_service.dart';
import '../../../services/locale_service.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../widgets/chat_bottom_sheet.dart';
import '../services/project_service.dart';
import '../providers/project_provider.dart';
import '../widgets/project_card.dart';
import '../widgets/project_list_widgets.dart';
import '../widgets/project_detail_widgets.dart';
import '../widgets/project_overview_tab.dart';
import '../widgets/project_tasks_tab.dart';
import '../widgets/project_members_tab.dart';
import '../widgets/project_chat_tab.dart';

part 'project_screen_sections.dart';
part 'project_screen_helpers.dart';
part 'project_screen_dialogs.dart';
part 'project_screen_build.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  final _projectService = const ProjectService();
  bool _isLoading = true;
  String? _projectLoadError;
  List<dynamic> _projects = [];
  List<dynamic> _allUsers = [];
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _memberEmailController = TextEditingController();
  final TextEditingController _projectSearchController =
      TextEditingController();
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskDescController = TextEditingController();
  Map<String, dynamic>? _currentUser;
  List<dynamic> _projectTasks = [];
  bool _isLoadingProjectTasks = false;
  bool _projectTasksLoaded = false;
  String _taskPriority = 'Medium';
  String _taskFilter = 'All';
  DateTime? _taskDueDate;
  TimeOfDay? _taskDueTime;
  String _taskReminderType = 'none';
  int? _taskReminderOffset;
  bool _taskNotificationEnabled = false;
  String _projectSearchQuery = '';
  String _projectTab = 'All';
  String _roleFilter = 'All';
  String _typeFilter = 'All';
  String _sortBy = 'Recent';
  String? _selectedAssigneeId;
  final Map<String, Set<String>> _localPendingInviteIds = {};
  bool _isSavingProjectTask = false;

  void _updateProjectState(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProjects();
    });
    _initCurrentUser();
  }

  Future<void> _initCurrentUser() async {
    final user = await AuthService.getUserInfo();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _deleteProject(String projectId) async {
    try {
      await context.read<ProjectProvider>().deleteProject(projectId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleService.tr('Đã xóa dự án thành công!',
                en: 'Project deleted successfully!')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${LocaleService.tr('Lỗi khi xóa dự án:', en: 'Error deleting project:')} $e'),
            backgroundColor: Colors.amber[900],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmationDialog(String projectId, String projectName) {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = ThemeService.isDarkMode.value;
        final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);
        final subTextColor = ThemeService.getSubTextColor(isDark);

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AlertDialog(
            backgroundColor: dialogBg.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                  color: Colors.redAccent.withValues(alpha: 0.5), width: 1.5),
            ),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.redAccent, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    LocaleService.tr('XÓA DỰ ÁN?', en: 'DELETE PROJECT?'),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
            content: Text(
              '${LocaleService.tr('Bạn có chắc chắn muốn xóa dự án', en: 'Are you sure you want to delete project')} "$projectName"?\n${LocaleService.tr('Hành động này sẽ xóa toàn bộ task và không thể khôi phục!', en: 'This action will delete all tasks and cannot be undone!')}',
              style: TextStyle(color: subTextColor, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  LocaleService.tr('Hủy', en: 'Cancel'),
                  style: TextStyle(
                      color: ThemeService.getCaptionColor(isDark),
                      fontWeight: FontWeight.bold),
                ),
              ),
              PremiumButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close project details bottom sheet
                  _deleteProject(projectId);
                },
                backgroundColor: Colors.redAccent,
                child: Text(
                  LocaleService.tr('Xóa', en: 'Delete'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _memberEmailController.dispose();
    _projectSearchController.dispose();
    _taskTitleController.dispose();
    _taskDescController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    if (mounted) {
      await context.read<ProjectProvider>().loadProjects();
    }
  }

  Future<void> _loadUsers() async {
    try {
      // Gọi qua ProjectService
      final users = await _projectService.getUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
        });
      }
    } catch (_) {}
  }

  Future<void> _createProject() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    try {
      await context.read<ProjectProvider>().createProject(
        name: name,
        description: _descController.text.trim(),
      );
      _nameController.clear();
      _descController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleService.tr(
                'Đã khởi tạo dự án nhóm thành công!',
                en: 'Project created successfully!')),
            backgroundColor: const Color(0xFF06B6D4),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {}
  }

  Future<void> _updateProject(
    String projectId,
    Map<String, dynamic> payload,
  ) async {
    try {
      await context.read<ProjectProvider>().updateProject(
          projectId: projectId, payload: payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project updated successfully.'),
            backgroundColor: Color(0xFF06B6D4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating project: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<String?> _addMember(String projectId) async {
    final email = _memberEmailController.text.trim();
    if (email.isEmpty) return null;
    final fallbackUserId = _userIdByEmail(email);

    // Gọi qua ProjectService
    final result = await _projectService.addMember(
        projectId: projectId, email: email);

    if (result['success'] == true) {
      _memberEmailController.clear();
      _loadProjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleService.tr('Đã gửi lời mời tham gia dự án!',
                en: 'Project invitation sent!')),
            backgroundColor: Colors.indigo,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      final data = result['data'] as Map<String, dynamic>;
      return _extractUserId(data['invitedUserId']) ??
          _extractUserId(data['notification']?['user']) ??
          fallbackUserId;
    } else {
      final errorText = (result['error'] ?? '').toString().toLowerCase();
      if (fallbackUserId != null &&
          (errorText.contains('pending') ||
              errorText.contains('ch') ||
              errorText.contains('mời') ||
              errorText.contains('moi'))) {
        _memberEmailController.clear();
        return fallbackUserId;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ??
                LocaleService.tr('Có lỗi xảy ra.', en: 'An error occurred.')),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    return null;
  }

  void _showCreateProjectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = ThemeService.isDarkMode.value;
        final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AlertDialog(
            backgroundColor: dialogBg.withValues(alpha: 0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08)),
            ),
            title: Text(
              LocaleService.tr('TẠO DỰ ÁN MỚI', en: 'CREATE NEW PROJECT'),
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
                  controller: _nameController,
                  label: LocaleService.tr('Tên dự án *', en: 'Project name *'),
                  hintText: LocaleService.tr('Nhập tên dự án...',
                      en: 'Enter project name...'),
                  prefixIcon: Icons.folder_rounded,
                ),
                const SizedBox(height: 14),
                PremiumInputField(
                  controller: _descController,
                  label: LocaleService.tr('Mô tả dự án',
                      en: 'Project description'),
                  hintText: LocaleService.tr('Nhập mô tả dự án...',
                      en: 'Enter project description...'),
                  prefixIcon: Icons.description_outlined,
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
                  _createProject();
                  Navigator.pop(context);
                },
                backgroundColor: const Color(0xFF06B6D4),
                child: Text(LocaleService.tr('T�o', en: 'Create'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    )),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _loadProjectTasks(String projectId,
      [StateSetter? sheetSetState]) async {
    if (!mounted) return;
    setState(() => _isLoadingProjectTasks = true);
    sheetSetState?.call(() {});
    try {
      // Gọi qua ProjectService
      final tasks = await _projectService.getProjectTasks(projectId);
      _projectTasks = tasks;
      _projectTasksLoaded = true;
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingProjectTasks = false);
        sheetSetState?.call(() {});
      }
    }
  }

  Future<void> _createProjectTask(String projectId, StateSetter sheetSetState,
      [StateSetter? dialogSetState]) async {
    if (_isSavingProjectTask) return;
    final title = _taskTitleController.text.trim();
    if (title.isEmpty || _selectedAssigneeId == null || _taskDueDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task title, assignee, and due date are required.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    if (_combinedTaskDueDateTime().isBefore(DateTime.now())) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Due date and time cannot be in the past.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      if (mounted) {
        setState(() => _isSavingProjectTask = true);
        dialogSetState?.call(() {});
      }
      // Gọi qua ProjectService
      final result = await _projectService.createProjectTask(
        projectId: projectId,
        payload: {
          'title': title,
          'description': _taskDescController.text.trim(),
          'priority': _taskPriority,
          'assignedTo': _selectedAssigneeId,
          'project': projectId,
          ..._taskSchedulePayload(),
        },
      );
      if (result['success'] == true) {
        final createdTask = result['data'] as Map<String, dynamic>;
        final createdAssigneeId =
            _itemId(createdTask['assignedTo'] ?? createdTask['user']);
        if (createdAssigneeId.isNotEmpty &&
            createdAssigneeId != _selectedAssigneeId) {
          throw Exception('Task was not assigned to the selected member.');
        }
        _taskTitleController.clear();
        _taskDescController.clear();
        _resetTaskScheduleFields();
        if (mounted) Navigator.pop(context);
        await _loadProjectTasks(projectId, sheetSetState);
        await _loadProjects();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleService.tr('Đã phân task thành công!',
                  en: 'Task assigned successfully!')),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Cannot create task'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${LocaleService.tr('Lỗi khi phân task:', en: 'Error assigning task:')} $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingProjectTask = false);
        dialogSetState?.call(() {});
      }
    }
  }

  Future<void> _updateProjectTaskStatus(String projectId, String taskId,
      String status, StateSetter sheetSetState) async {
    try {
      // Gọi qua ProjectService
      final result = await _projectService.updateProjectTask(
        projectId: projectId,
        taskId: taskId,
        payload: {'status': status},
      );
      if (result['success'] == true) {
        await _loadProjectTasks(projectId, sheetSetState);
        await _loadProjects();
      }
    } catch (_) {}
  }

  Future<String?> _updateProjectTask(
    String projectId,
    String taskId,
    Map<String, dynamic> payload,
    StateSetter sheetSetState,
  ) async {
    // Gọi qua ProjectService
    final result = await _projectService.updateProjectTask(
      projectId: projectId,
      taskId: taskId,
      payload: payload,
    );
    if (result['success'] == true) {
      if (mounted) Navigator.pop(context);
      await _loadProjectTasks(projectId, sheetSetState);
      await _loadProjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(LocaleService.tr('Đã cập nhật task thành công!',
                en: 'Task updated successfully!')),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
    final statusCode = result['statusCode'] as int?;
    if (statusCode == 404 || statusCode == 405) {
      return LocaleService.tr(
          'Backend chưa cập nhật API sửa task dự án. Cần deploy backend mới.',
          en: 'Project task edit API is not deployed yet. Please deploy the updated backend.');
    }
    return (result['error'] ?? 'Cannot update task').toString();
  }

  Future<bool> _updateMemberRole(String projectId, String userId, String role,
      Map<String, dynamic> projectData, StateSetter sheetSetState) async {
    try {
      // Gọi qua ProjectService
      final result = await _projectService.updateMemberRole(
        projectId: projectId,
        userId: userId,
        role: role,
      );
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        projectData['project'] = data['project'];
        projectData['currentUserRole'] = data['currentUserRole'];
        await _loadProjects();
        sheetSetState(() {});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member role updated successfully'),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return true;
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                (result['error'] ?? 'Cannot update member role').toString()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating member role: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => _buildProjectScreen(context);
}
