import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/locale_service.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/chat_bottom_sheet.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  bool _isLoading = true;
  List<dynamic> _projects = [];
  List<dynamic> _allUsers = [];
  bool _isLoadingUsers = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _memberEmailController = TextEditingController();
  final TextEditingController _taskTitleController = TextEditingController();
  final TextEditingController _taskDescController = TextEditingController();
  Map<String, dynamic>? _currentUser;
  List<dynamic> _projectTasks = [];
  bool _isLoadingProjectTasks = false;
  bool _projectTasksLoaded = false;
  String _taskPriority = 'Medium';
  String? _selectedAssigneeId;
  final Map<String, Set<String>> _localPendingInviteIds = {};

  @override
  void initState() {
    super.initState();
    _loadProjects();
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
      final token = await AuthService.getToken();
      final response = await http.delete(
        Uri.parse('https://prm-tan.vercel.app/api/projects/$projectId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
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
        _loadProjects();
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ??
            LocaleService.tr('Xóa thất bại', en: 'Deletion failed'));
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
            backgroundColor: dialogBg.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                  color: Colors.redAccent.withOpacity(0.5), width: 1.5),
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
    _taskTitleController.dispose();
    _taskDescController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('https://prm-tan.vercel.app/api/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> rawProjects = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _projects = rawProjects.map((p) {
              if (p is Map<String, dynamic> && p.containsKey('project')) {
                return p;
              }

              return {
                'project': p,
                'stats': {
                  'totalTasks': 0,
                  'completedTasks': 0,
                  'progressPercentage': 0,
                },
              };
            }).toList();
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

  Future<void> _loadUsers() async {
    try {
      setState(() => _isLoadingUsers = true);

      final token = await AuthService.getToken();

      final response = await http.get(
        Uri.parse('https://prm-tan.vercel.app/api/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _allUsers = data;
            _isLoadingUsers = false;
          });
        }
      } else {
        setState(() => _isLoadingUsers = false);
      }
    } catch (e) {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _createProject() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    try {
      final token = await AuthService.getToken();
      final response = await http
          .post(
            Uri.parse('https://prm-tan.vercel.app/api/projects'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'name': name,
              'description': _descController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
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
        _loadProjects();
      }
    } catch (_) {}
  }

  Future<String?> _addMember(String projectId) async {
    final email = _memberEmailController.text.trim();
    if (email.isEmpty) return null;
    final fallbackUserId = _userIdByEmail(email);

    try {
      final token = await AuthService.getToken();
      final response = await http
          .post(
            Uri.parse(
                'https://prm-tan.vercel.app/api/projects/$projectId/members'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
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
        return _extractUserId(data['invitedUserId']) ??
            _extractUserId(data['notification']?['user']) ??
            fallbackUserId;
      } else {
        final errorText = (data['error'] ?? '').toString().toLowerCase();
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
              content: Text(data['error'] ??
                  LocaleService.tr('Có lỗi xảy ra.', en: 'An error occurred.')),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {}
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
            backgroundColor: dialogBg.withOpacity(0.9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.08)),
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
                child: Text(LocaleService.tr('Tạo', en: 'Create'),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  String _itemId(dynamic item) {
    if (item is Map<String, dynamic>) {
      return (item['_id'] ?? item['id'] ?? '').toString();
    }
    return item?.toString() ?? '';
  }

  String? _extractUserId(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      final id = _itemId(value);
      return id.isEmpty ? null : id;
    }
    final id = value.toString();
    return id.isEmpty ? null : id;
  }

  String? _userIdByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final user in _allUsers) {
      if (user is Map<String, dynamic> &&
          (user['email'] ?? '').toString().toLowerCase() == normalized) {
        final id = _itemId(user);
        return id.isEmpty ? null : id;
      }
    }
    return null;
  }

  String _currentUserId() =>
      (_currentUser?['_id'] ?? _currentUser?['id'] ?? '').toString();

  String _memberDisplayName(dynamic user) {
    if (user is! Map<String, dynamic>) return '';
    final name = user['name']?.toString() ?? '';
    if (name.isNotEmpty) return name;
    final email = user['email']?.toString() ?? '';
    return email.contains('@') ? email.split('@')[0] : email;
  }

  String _assigneeDisplayName(dynamic assignee, Map<String, dynamic> project) {
    if (assignee is Map<String, dynamic>) {
      final name = _memberDisplayName(assignee);
      if (name.isNotEmpty) {
        return name;
      }
    }

    final assigneeId = _itemId(assignee);
    if (assigneeId.isEmpty) {
      return LocaleService.tr('Chua gan', en: 'Unassigned');
    }

    for (final user in _projectParticipants(project)) {
      if (_itemId(user) == assigneeId) {
        final name = _memberDisplayName(user);
        if (name.isNotEmpty) {
          return name;
        }
      }
    }

    return assigneeId;
  }

  List<dynamic> _projectParticipants(Map<String, dynamic> project) {
    final owner = project['owner'];
    final members = project['members'] as List<dynamic>? ?? [];
    return [if (owner != null) owner, ...members];
  }

  Set<String> _pendingInvitationIds(Map<String, dynamic> projectData) {
    final pending =
        projectData['pendingInvitationUserIds'] as List<dynamic>? ?? [];
    final project = projectData['project'] as Map<String, dynamic>? ?? {};
    final local =
        _localPendingInviteIds[project['_id']?.toString() ?? ''] ?? {};
    return {...pending.map((id) => id.toString()), ...local};
  }

  void _markInvited(Map<String, dynamic> projectData, String userId) {
    final pending =
        projectData['pendingInvitationUserIds'] as List<dynamic>? ?? [];
    if (!pending.map((id) => id.toString()).contains(userId)) {
      projectData['pendingInvitationUserIds'] = [...pending, userId];
    }
    final project = projectData['project'] as Map<String, dynamic>? ?? {};
    final projectId = project['_id']?.toString() ?? '';
    if (projectId.isNotEmpty) {
      _localPendingInviteIds
          .putIfAbsent(projectId, () => <String>{})
          .add(userId);
    }
  }

  String _roleForUser(Map<String, dynamic> project, String userId) {
    if (_itemId(project['owner']) == userId) return 'Owner';
    final roles = project['memberRoles'] as List<dynamic>? ?? [];
    for (final entry in roles) {
      if (entry is Map<String, dynamic> && _itemId(entry['user']) == userId) {
        return (entry['role'] ?? 'Member').toString();
      }
    }
    return 'Member';
  }

  Color _roleColor(String role) {
    if (role == 'Owner') return const Color(0xFFEAB308);
    if (role == 'Manager') return const Color(0xFF8B5CF6);
    return const Color(0xFF06B6D4);
  }

  Color _statusColor(String status) {
    if (status == 'Completed') return const Color(0xFF10B981);
    if (status == 'In Progress') return const Color(0xFF06B6D4);
    if (status == 'Overdue') return const Color(0xFFF43F5E);
    return const Color(0xFFEAB308);
  }

  bool _canManage(String? role) => role == 'Owner' || role == 'Manager';

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Future<void> _loadProjectTasks(String projectId,
      [StateSetter? sheetSetState]) async {
    if (!mounted) return;
    setState(() => _isLoadingProjectTasks = true);
    sheetSetState?.call(() {});

    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        Uri.parse('https://prm-tan.vercel.app/api/projects/$projectId/tasks'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _projectTasks = jsonDecode(response.body);
        _projectTasksLoaded = true;
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoadingProjectTasks = false);
        sheetSetState?.call(() {});
      }
    }
  }

  Future<void> _createProjectTask(
      String projectId, StateSetter sheetSetState) async {
    final title = _taskTitleController.text.trim();
    if (title.isEmpty || _selectedAssigneeId == null) return;

    try {
      final token = await AuthService.getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final body = jsonEncode({
        'title': title,
        'description': _taskDescController.text.trim(),
        'priority': _taskPriority,
        'assignedTo': _selectedAssigneeId,
        'project': projectId,
      });

      final response = await http
          .post(
            Uri.parse(
                'https://prm-tan.vercel.app/api/projects/$projectId/tasks'),
            headers: headers,
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final createdTask = response.body.isNotEmpty
            ? jsonDecode(response.body) as Map<String, dynamic>
            : <String, dynamic>{};
        final createdAssigneeId =
            _itemId(createdTask['assignedTo'] ?? createdTask['user']);
        if (createdAssigneeId.isNotEmpty &&
            createdAssigneeId != _selectedAssigneeId) {
          throw Exception('Task was not assigned to the selected member.');
        }
        _taskTitleController.clear();
        _taskDescController.clear();
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
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['error'] ?? 'Cannot create task'),
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
    }
  }

  Future<void> _updateProjectTaskStatus(String projectId, String taskId,
      String status, StateSetter sheetSetState) async {
    try {
      final token = await AuthService.getToken();
      final response = await http
          .put(
            Uri.parse(
                'https://prm-tan.vercel.app/api/projects/$projectId/tasks/$taskId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'status': status}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
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
    try {
      final token = await AuthService.getToken();
      final response = await http
          .put(
            Uri.parse(
                'https://prm-tan.vercel.app/api/projects/$projectId/tasks/$taskId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
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
      } else if (mounted) {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        if (response.statusCode == 404 || response.statusCode == 405) {
          return LocaleService.tr(
              'Backend chưa cập nhật API sửa task dự án. Cần deploy backend mới.',
              en: 'Project task edit API is not deployed yet. Please deploy the updated backend.');
        }
        return (data['error'] ?? 'Cannot update task').toString();
      }
      return 'Cannot update task';
    } catch (e) {
      return '${LocaleService.tr('Lỗi khi cập nhật task:', en: 'Error updating task:')} $e';
    }
  }

  Future<void> _updateMemberRole(String projectId, String userId, String role,
      Map<String, dynamic> projectData, StateSetter sheetSetState) async {
    try {
      final token = await AuthService.getToken();
      final response = await http
          .put(
            Uri.parse(
                'https://prm-tan.vercel.app/api/projects/$projectId/members/$userId/role'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'role': role}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        projectData['project'] = data['project'];
        projectData['currentUserRole'] = data['currentUserRole'];
        await _loadProjects();
        sheetSetState(() {});
      }
    } catch (_) {}
  }

  void _showCreateProjectTaskDialog(
      Map<String, dynamic> project, StateSetter sheetSetState) {
    final participants = _projectParticipants(project);
    _selectedAssigneeId = participants.isNotEmpty
        ? _itemId(participants.first)
        : _currentUserId();

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
                backgroundColor: dialogBg.withOpacity(0.94),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text(
                  LocaleService.tr('PHAN TASK', en: 'ASSIGN TASK'),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PremiumInputField(
                        controller: _taskTitleController,
                        label:
                            LocaleService.tr('Ten task *', en: 'Task title *'),
                        hintText: LocaleService.tr('Nhap ten task...',
                            en: 'Enter task...'),
                        prefixIcon: Icons.task_alt_rounded,
                      ),
                      const SizedBox(height: 12),
                      PremiumInputField(
                        controller: _taskDescController,
                        label: LocaleService.tr('Mo ta', en: 'Description'),
                        hintText: LocaleService.tr('Nhap mo ta...',
                            en: 'Enter details...'),
                        prefixIcon: Icons.description_outlined,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _selectedAssigneeId,
                        dropdownColor: dialogBg,
                        decoration: InputDecoration(
                          labelText: LocaleService.tr('Nguoi nhan task',
                              en: 'Assignee'),
                        ),
                        items: participants.map((user) {
                          final id = _itemId(user);
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(
                              _memberDisplayName(user),
                              style: TextStyle(color: textColor),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setDialogState(() => _selectedAssigneeId = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _taskPriority,
                        dropdownColor: dialogBg,
                        decoration: InputDecoration(
                          labelText:
                              LocaleService.tr('Do uu tien', en: 'Priority'),
                        ),
                        items: ['Low', 'Medium', 'High']
                            .map(
                              (priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority,
                                    style: TextStyle(color: textColor)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => _taskPriority = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(LocaleService.tr('Huy', en: 'Cancel'),
                        style: TextStyle(color: captionColor)),
                  ),
                  PremiumButton(
                    onPressed: () =>
                        _createProjectTask(project['_id'], sheetSetState),
                    backgroundColor: const Color(0xFF06B6D4),
                    child: const Text('Assign',
                        style: TextStyle(
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

  Widget _buildProjectOverviewTab(
    Map<String, dynamic> project,
    Map<String, dynamic> stats,
    Color textColor,
    Color subTextColor,
    Color captionColor,
    bool isDark,
  ) {
    final total = stats['totalTasks'] ?? 0;
    final completed = stats['completedTasks'] ?? 0;
    final progress = stats['progressPercentage'] ?? 0;
    final members = project['members'] as List<dynamic>? ?? [];

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        GlassCard(
          borderRadius: 20,
          padding: const EdgeInsets.all(18),
          child: Text(
            project['description']?.toString().isNotEmpty == true
                ? project['description']
                : LocaleService.tr('Chua co mo ta chi tiet.',
                    en: 'No detailed description.'),
            style: TextStyle(color: subTextColor, fontSize: 14, height: 1.4),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildOverviewMetric(
                'Progress',
                '$progress%',
                Icons.trending_up_rounded,
                const Color(0xFF06B6D4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewMetric(
                'Tasks',
                '$completed/$total',
                Icons.task_alt_rounded,
                const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildOverviewMetric(
                'Members',
                '${members.length + 1}',
                Icons.people_alt_rounded,
                const Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildOverviewMetric(
                'Status',
                project['status'] ?? 'Active',
                Icons.flag_rounded,
                const Color(0xFFEAB308),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOverviewMetric(
      String label, String value, IconData icon, Color color) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: captionColor, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildProjectTasksTab(
    Map<String, dynamic> project,
    bool canManage,
    Color textColor,
    Color subTextColor,
    Color captionColor,
    StateSetter sheetSetState,
  ) {
    return Column(
      children: [
        if (canManage)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Align(
              alignment: Alignment.centerRight,
              child: PremiumButton.icon(
                onPressed: () =>
                    _showCreateProjectTaskDialog(project, sheetSetState),
                icon: Icons.add_task_rounded,
                label: LocaleService.tr('Phan task', en: 'Assign task'),
                backgroundColor: const Color(0xFF06B6D4),
              ),
            ),
          ),
        Expanded(
          child: _isLoadingProjectTasks
              ? const Center(child: CircularProgressIndicator())
              : _projectTasks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _projectTasksLoaded
                                ? LocaleService.tr('Chua co task trong du an.',
                                    en: 'No project tasks yet.')
                                : LocaleService.tr('Task chua duoc tai.',
                                    en: 'Tasks are not loaded yet.'),
                            style: TextStyle(color: captionColor),
                          ),
                          if (!_projectTasksLoaded) ...[
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () => _loadProjectTasks(
                                  project['_id'], sheetSetState),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Load tasks'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      itemCount: _projectTasks.length,
                      itemBuilder: (context, index) {
                        final task = _projectTasks[index];
                        final status = task['status'] ?? 'Pending';
                        final assignee = task['assignedTo'] ?? task['user'];
                        final assignedToMe =
                            _itemId(assignee) == _currentUserId();
                        final canUpdate = canManage || assignedToMe;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            borderRadius: 18,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: _statusColor(status),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        task['title'] ?? 'Untitled task',
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Assigned to ${_assigneeDisplayName(assignee, project)}',
                                        style: TextStyle(
                                            color: captionColor, fontSize: 11),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          _buildBadge(
                                              status, _statusColor(status)),
                                          _buildBadge(
                                            task['priority'] ?? 'Medium',
                                            const Color(0xFF8B5CF6),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (canUpdate)
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert_rounded,
                                        color: captionColor),
                                    onSelected: (value) {
                                      if (value == '__edit') {
                                        _showEditProjectTaskDialog(
                                            project, task, sheetSetState);
                                        return;
                                      }

                                      _updateProjectTaskStatus(
                                        project['_id'],
                                        task['_id'],
                                        value,
                                        sheetSetState,
                                      );
                                    },
                                    itemBuilder: (context) => [
                                      if (canManage)
                                        const PopupMenuItem(
                                          value: '__edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined,
                                                  size: 18),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                      if (canManage) const PopupMenuDivider(),
                                      ...[
                                        'Pending',
                                        'In Progress',
                                        'Completed',
                                        'Overdue'
                                      ].map((value) => PopupMenuItem(
                                            value: value,
                                            child: Text(value),
                                          )),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildProjectMembersTab(
    Map<String, dynamic> projectData,
    bool isOwner,
    bool canManage,
    Color textColor,
    Color captionColor,
    StateSetter sheetSetState,
  ) {
    final project = projectData['project'] as Map<String, dynamic>;
    final members = project['members'] as List<dynamic>? ?? [];
    final participants = _projectParticipants(project);
    final pendingInvitationIds = _pendingInvitationIds(projectData);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        if (canManage) ...[
          Row(
            children: [
              Expanded(
                child: PremiumInputField(
                  controller: _memberEmailController,
                  label:
                      LocaleService.tr('Moi thanh vien', en: 'Invite member'),
                  hintText:
                      LocaleService.tr('Nhap email...', en: 'Enter email...'),
                  prefixIcon: Icons.mail_outline_rounded,
                ),
              ),
              const SizedBox(width: 10),
              PremiumButton(
                onPressed: () async {
                  final invitedUserId = await _addMember(project['_id']);
                  if (invitedUserId != null) {
                    _markInvited(projectData, invitedUserId);
                  }
                  sheetSetState(() {});
                },
                backgroundColor: const Color(0xFF06B6D4),
                child: const Text('Invite',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        ...participants.map((user) {
          final userId = _itemId(user);
          final role = _roleForUser(project, userId);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              borderRadius: 18,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: _roleColor(role),
                    child: Icon(
                      role == 'Owner'
                          ? Icons.star_rounded
                          : Icons.person_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_memberDisplayName(user),
                            style: TextStyle(
                                color: textColor, fontWeight: FontWeight.bold)),
                        Text(
                          user is Map<String, dynamic>
                              ? (user['email'] ?? '').toString()
                              : '',
                          style: TextStyle(color: captionColor, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (isOwner && role != 'Owner')
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: role,
                        dropdownColor: ThemeService.getDialogBackgroundColor(
                            ThemeService.isDarkMode.value),
                        items: ['Manager', 'Member']
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value,
                                    style: TextStyle(color: textColor)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _updateMemberRole(project['_id'], userId, value,
                                projectData, sheetSetState);
                          }
                        },
                      ),
                    )
                  else
                    _buildBadge(role, _roleColor(role)),
                ],
              ),
            ),
          );
        }),
        if (canManage && _allUsers.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Suggested',
              style: TextStyle(
                  color: captionColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          const SizedBox(height: 10),
          ..._allUsers.take(8).map((user) {
            final alreadyMember =
                members.any((m) => _itemId(m) == _itemId(user)) ||
                    _itemId(project['owner']) == _itemId(user);
            final invited = pendingInvitationIds.contains(_itemId(user));
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Opacity(
                opacity: alreadyMember || invited ? 0.55 : 1,
                child: GlassCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFF06B6D4),
                        child:
                            Icon(Icons.person, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_memberDisplayName(user),
                            style: TextStyle(color: textColor)),
                      ),
                      if (!alreadyMember && !invited)
                        TextButton(
                          onPressed: () async {
                            _memberEmailController.text =
                                (user['email'] ?? '').toString();
                            final invitedUserId =
                                await _addMember(project['_id']);
                            if (invitedUserId != null) {
                              _markInvited(projectData, invitedUserId);
                            }
                            sheetSetState(() {});
                          },
                          child: const Text('Invite'),
                        )
                      else
                        Text(invited ? 'Invited' : 'Joined',
                            style: TextStyle(
                                color: invited
                                    ? const Color(0xFF8B5CF6)
                                    : captionColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildProjectChatTab(
    Map<String, dynamic> project,
    Color textColor,
    Color subTextColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 56, color: subTextColor),
            const SizedBox(height: 16),
            Text(
              LocaleService.tr('Chat chi tai khi ban mo.',
                  en: 'Chat loads only when opened.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: subTextColor, fontSize: 14),
            ),
            const SizedBox(height: 18),
            PremiumButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => ChatBottomSheet(
                    projectId: project['_id'],
                    projectName: project['name'] ??
                        LocaleService.tr('Du an', en: 'Project'),
                  ),
                );
              },
              icon: Icons.chat_bubble_rounded,
              label: LocaleService.tr('Mo chat', en: 'Open chat'),
              backgroundColor: const Color(0xFF06B6D4),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProjectTaskDialog(Map<String, dynamic> project,
      Map<String, dynamic> task, StateSetter sheetSetState) {
    final participants = _projectParticipants(project);
    final currentAssigneeId = _itemId(task['assignedTo'] ?? task['user']);
    _taskTitleController.text = (task['title'] ?? '').toString();
    _taskDescController.text = (task['description'] ?? '').toString();
    _taskPriority = (task['priority'] ?? 'Medium').toString();
    _selectedAssigneeId =
        participants.any((user) => _itemId(user) == currentAssigneeId)
            ? currentAssigneeId
            : (participants.isNotEmpty
                ? _itemId(participants.first)
                : _currentUserId());
    String taskStatus = (task['status'] ?? 'Pending').toString();
    bool isSaving = false;
    String? editError;

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
                backgroundColor: dialogBg.withOpacity(0.94),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text(
                  LocaleService.tr('SUA TASK', en: 'EDIT TASK'),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PremiumInputField(
                        controller: _taskTitleController,
                        label:
                            LocaleService.tr('Ten task *', en: 'Task title *'),
                        hintText: LocaleService.tr('Nhap ten task...',
                            en: 'Enter task...'),
                        prefixIcon: Icons.task_alt_rounded,
                      ),
                      const SizedBox(height: 12),
                      PremiumInputField(
                        controller: _taskDescController,
                        label: LocaleService.tr('Mo ta', en: 'Description'),
                        hintText: LocaleService.tr('Nhap mo ta...',
                            en: 'Enter details...'),
                        prefixIcon: Icons.description_outlined,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _selectedAssigneeId,
                        dropdownColor: dialogBg,
                        decoration: InputDecoration(
                          labelText: LocaleService.tr('Nguoi nhan task',
                              en: 'Assignee'),
                        ),
                        items: participants.map((user) {
                          final id = _itemId(user);
                          return DropdownMenuItem<String>(
                            value: id,
                            child: Text(_memberDisplayName(user),
                                style: TextStyle(color: textColor)),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setDialogState(() => _selectedAssigneeId = value),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _taskPriority,
                        dropdownColor: dialogBg,
                        decoration: InputDecoration(
                          labelText:
                              LocaleService.tr('Do uu tien', en: 'Priority'),
                        ),
                        items: ['Low', 'Medium', 'High']
                            .map((priority) => DropdownMenuItem(
                                  value: priority,
                                  child: Text(priority,
                                      style: TextStyle(color: textColor)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => _taskPriority = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: taskStatus,
                        dropdownColor: dialogBg,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items:
                            ['Pending', 'In Progress', 'Completed', 'Overdue']
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status,
                                          style: TextStyle(color: textColor)),
                                    ))
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => taskStatus = value);
                          }
                        },
                      ),
                      if (editError != null) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            editError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    child: Text(LocaleService.tr('Huy', en: 'Cancel'),
                        style: TextStyle(color: captionColor)),
                  ),
                  PremiumButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final title = _taskTitleController.text.trim();
                            if (title.isEmpty || _selectedAssigneeId == null) {
                              setDialogState(() {
                                editError = LocaleService.tr(
                                    'Vui lòng nhập đầy đủ thông tin.',
                                    en: 'Please fill in all required fields.');
                              });
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                              editError = null;
                            });

                            final error = await _updateProjectTask(
                              project['_id'],
                              task['_id'],
                              {
                                'title': title,
                                'description': _taskDescController.text.trim(),
                                'priority': _taskPriority,
                                'assignedTo': _selectedAssigneeId,
                                'status': taskStatus,
                              },
                              sheetSetState,
                            );
                            if (error != null && mounted) {
                              setDialogState(() {
                                isSaving = false;
                                editError = error;
                              });
                            }
                          },
                    backgroundColor: const Color(0xFF06B6D4),
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showProjectDetails(Map<String, dynamic> projectData) {
    _loadUsers();
    _projectTasks = [];
    _projectTasksLoaded = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            final project = projectData['project'] as Map<String, dynamic>;
            final stats = projectData['stats'] as Map<String, dynamic>? ?? {};
            final role = (projectData['currentUserRole'] ??
                    _roleForUser(project, _currentUserId()))
                .toString();
            final canManage = _canManage(role);
            final isOwner = role == 'Owner';
            final isDark = ThemeService.isDarkMode.value;
            final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
            final textColor = ThemeService.getTextColor(isDark);
            final subTextColor = ThemeService.getSubTextColor(isDark);
            final captionColor = ThemeService.getCaptionColor(isDark);
            final borderColor = ThemeService.getBorderColor(isDark);
            const themeColor = Color(0xFF06B6D4);
            final progress = stats['progressPercentage'] ?? 0;
            final total = stats['totalTasks'] ?? 0;
            final completed = stats['completedTasks'] ?? 0;

            return DefaultTabController(
              length: 4,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.88,
                  decoration: BoxDecoration(
                    color: dialogBg.withOpacity(0.92),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Container(
                                width: 50,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: captionColor.withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project['name'] ??
                                            LocaleService.tr('Du an',
                                                en: 'Project'),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          _buildBadge(role, _roleColor(role)),
                                          const SizedBox(width: 8),
                                          Text(
                                            '$completed/$total tasks',
                                            style: TextStyle(
                                                color: captionColor,
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOwner)
                                  IconButton(
                                    onPressed: () =>
                                        _showDeleteConfirmationDialog(
                                            project['_id'],
                                            project['name'] ?? ''),
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.redAccent),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: progress / 100.0,
                                minHeight: 7,
                                backgroundColor: isDark
                                    ? Colors.white.withOpacity(0.06)
                                    : Colors.black.withOpacity(0.06),
                                valueColor:
                                    const AlwaysStoppedAnimation(themeColor),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TabBar(
                              labelColor: themeColor,
                              unselectedLabelColor: captionColor,
                              indicatorColor: themeColor,
                              labelStyle: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                              tabs: const [
                                Tab(text: 'Overview'),
                                Tab(text: 'Tasks'),
                                Tab(text: 'Members'),
                                Tab(text: 'Chat'),
                              ],
                              onTap: (index) {
                                if (index == 1 && _projectTasks.isEmpty) {
                                  _loadProjectTasks(
                                      project['_id'], sheetSetState);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildProjectOverviewTab(
                              project,
                              stats,
                              textColor,
                              subTextColor,
                              captionColor,
                              isDark,
                            ),
                            _buildProjectTasksTab(
                              project,
                              canManage,
                              textColor,
                              subTextColor,
                              captionColor,
                              sheetSetState,
                            ),
                            _buildProjectMembersTab(
                              projectData,
                              isOwner,
                              canManage,
                              textColor,
                              captionColor,
                              sheetSetState,
                            ),
                            _buildProjectChatTab(
                              project,
                              textColor,
                              subTextColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ignore: unused_element
  void _showLegacyProjectDetails(Map<String, dynamic> projectData) {
    _loadUsers();

    final project = projectData['project'];
    final members = project['members'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = ThemeService.isDarkMode.value;
        final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);
        final subTextColor = ThemeService.getSubTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);
        final borderColor = ThemeService.getBorderColor(isDark);

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: dialogBg.withOpacity(0.85),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(36),
                topRight: Radius.circular(36),
              ),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.15)
                          : Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        project['name'] ??
                            LocaleService.tr('Dự án không tên',
                                en: 'Untitled project'),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_currentUser?['_id'] == project['owner']?['_id'] ||
                            _currentUser?['id'] == project['owner']?['id']) ...[
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent, size: 24),
                            onPressed: () => _showDeleteConfirmationDialog(
                                project['_id'], project['name'] ?? ''),
                          ),
                          const SizedBox(width: 8),
                        ],
                        PremiumButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => ChatBottomSheet(
                                projectId: project['_id'],
                                projectName: project['name'] ??
                                    LocaleService.tr('Dự án không tên',
                                        en: 'Untitled project'),
                              ),
                            );
                          },
                          icon: Icons.chat_bubble_rounded,
                          label: LocaleService.tr('Chat', en: 'Chat'),
                          backgroundColor: const Color(0xFF06B6D4),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  project['description']?.toString().isNotEmpty == true
                      ? project['description']
                      : LocaleService.tr('Không có mô tả chi tiết.',
                          en: 'No detailed description.'),
                  style: TextStyle(fontSize: 14, color: subTextColor),
                ),
                const SizedBox(height: 24),

                // Members Title & Add Member
                Text(
                    LocaleService.tr('THÀNH VIÊN DỰ ÁN', en: 'PROJECT MEMBERS'),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: captionColor,
                        letterSpacing: 2)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PremiumInputField(
                        controller: _memberEmailController,
                        label: LocaleService.tr('Mời thành viên',
                            en: 'Invite member'),
                        hintText: LocaleService.tr('Nhập email thành viên...',
                            en: 'Enter member email...'),
                        prefixIcon: Icons.mail_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    PremiumButton(
                      onPressed: () {
                        _addMember(project['_id']);
                        Navigator.pop(context);
                      },
                      backgroundColor: const Color(0xFF06B6D4),
                      child: Text(LocaleService.tr('Mời', en: 'Invite'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Members List
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length + 1,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final owner = project['owner'];
                        return FadeInSlide(
                          delayMs: 50,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: GlassCard(
                              borderRadius: 18,
                              padding: const EdgeInsets.all(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEAB308)
                                      .withOpacity(isDark ? 0.05 : 0.03),
                                  blurRadius: 10,
                                )
                              ],
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFEAB308),
                                    radius: 18,
                                    child: Icon(Icons.star_rounded,
                                        size: 18, color: Colors.white),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              owner['name']
                                                          ?.toString()
                                                          .isNotEmpty ==
                                                      true
                                                  ? owner['name']
                                                  : owner['email']
                                                      .split('@')[0],
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEAB308)
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                  LocaleService.tr('CHỦ DỰ ÁN',
                                                      en: 'OWNER'),
                                                  style: const TextStyle(
                                                      color: Color(0xFFEAB308),
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w900)),
                                            )
                                          ],
                                        ),
                                        Text(owner['email'],
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: captionColor)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final member = members[index - 1];
                      return FadeInSlide(
                        delayMs: index * 60,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: GlassCard(
                            borderRadius: 18,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFF06B6D4),
                                  radius: 18,
                                  child: Icon(Icons.person_rounded,
                                      size: 18, color: Colors.white),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member['name']?.toString().isNotEmpty ==
                                              true
                                          ? member['name']
                                          : member['email'].split('@')[0],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor),
                                    ),
                                    Text(member['email'],
                                        style: TextStyle(
                                            fontSize: 12, color: captionColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Suggested users list
                Text(
                  LocaleService.tr(
                    'GỢI Ý THÀNH VIÊN',
                    en: 'SUGGESTED MEMBERS',
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: captionColor,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 180,
                  child: _isLoadingUsers
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : _allUsers.isEmpty
                          ? Center(
                              child: Text(
                                LocaleService.tr(
                                  'Không có người dùng nào',
                                  en: 'No users found',
                                ),
                                style: TextStyle(color: captionColor),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _allUsers.length,
                              itemBuilder: (context, index) {
                                final user = _allUsers[index];

                                final alreadyMember = members
                                        .any((m) => m['_id'] == user['_id']) ||
                                    project['owner']['_id'] == user['_id'];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Opacity(
                                    opacity: alreadyMember ? 0.5 : 1,
                                    child: GlassCard(
                                      borderRadius: 18,
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor:
                                                const Color(0xFF06B6D4),
                                            backgroundImage: user['profile']
                                                            ?['avatarUrl'] !=
                                                        null &&
                                                    user['profile']['avatarUrl']
                                                        .toString()
                                                        .isNotEmpty
                                                ? NetworkImage(
                                                    user['profile']
                                                        ['avatarUrl'],
                                                  )
                                                : null,
                                            child: user['profile']
                                                            ?['avatarUrl'] ==
                                                        null ||
                                                    user['profile']['avatarUrl']
                                                        .toString()
                                                        .isEmpty
                                                ? const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user['name']
                                                              ?.toString()
                                                              .isNotEmpty ==
                                                          true
                                                      ? user['name']
                                                      : user['email']
                                                          .split('@')[0],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor,
                                                  ),
                                                ),
                                                Text(
                                                  user['email'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: captionColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          alreadyMember
                                              ? Text(
                                                  LocaleService.tr(
                                                    'Đã tham gia',
                                                    en: 'Joined',
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                )
                                              : PremiumButton(
                                                  onPressed: () async {
                                                    _memberEmailController
                                                        .text = user['email'];

                                                    await _addMember(
                                                        project['_id']);
                                                  },
                                                  backgroundColor:
                                                      const Color(0xFF06B6D4),
                                                  child: Text(
                                                    LocaleService.tr(
                                                      'Thêm',
                                                      en: 'Add',
                                                    ),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF06B6D4);

    return ListenableBuilder(
      listenable: Listenable.merge(
          [ThemeService.isDarkMode, LocaleService.languageCode]),
      builder: (context, child) {
        final isDark = ThemeService.isDarkMode.value;
        final textColor = ThemeService.getTextColor(isDark);
        final subTextColor = ThemeService.getSubTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);

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
                          LocaleService.tr('HỢP TÁC ĐỒNG ĐỘI',
                              en: 'TEAM COLLABORATION'),
                          style: TextStyle(
                              color: captionColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2),
                        ),
                        Text(
                          LocaleService.tr('Dự Án Nhóm', en: 'Team Projects'),
                          style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    PremiumButton.icon(
                      onPressed: _showCreateProjectDialog,
                      icon: Icons.add,
                      label: LocaleService.tr('Tạo dự án', en: 'New project'),
                      backgroundColor: themeColor,
                    )
                  ],
                ),
                const SizedBox(height: 18),

                // Projects List
                Expanded(
                  child: _isLoading
                      ? ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 4,
                          itemBuilder: (context, index) => const Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: ShimmerLoading(
                                width: double.infinity,
                                height: 160,
                                borderRadius: 24),
                          ),
                        )
                      : _projects.isEmpty
                          ? FadeInSlide(
                              delayMs: 100,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.dns_outlined,
                                        size: 54,
                                        color: captionColor.withOpacity(0.4)),
                                    const SizedBox(height: 12),
                                    Text(
                                        LocaleService.tr('Chưa có dự án nào.',
                                            en: 'No projects yet.'),
                                        style: TextStyle(
                                            color: captionColor, fontSize: 14)),
                                  ],
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadProjects,
                              color: themeColor,
                              child: ListView.builder(
                                itemCount: _projects.length,
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final projectData = _projects[index];
                                  final project = projectData['project'];
                                  final stats = projectData['stats'];

                                  final name = project['name'] ??
                                      LocaleService.tr('Dự án không tên',
                                          en: 'Untitled project');
                                  final desc = project['description'] ?? '';
                                  final total = stats['totalTasks'] ?? 0;
                                  final completed =
                                      stats['completedTasks'] ?? 0;
                                  final progress =
                                      stats['progressPercentage'] ?? 0;
                                  final members =
                                      project['members'] as List<dynamic>? ??
                                          [];
                                  final currentRole =
                                      (projectData['currentUserRole'] ??
                                              _roleForUser(
                                                  project, _currentUserId()))
                                          .toString();

                                  return FadeInSlide(
                                    delayMs: index * 80,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12.0),
                                      child: GestureDetector(
                                        onTap: () =>
                                            _showProjectDetails(projectData),
                                        child: GlassCard(
                                          borderRadius: 24,
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: textColor),
                                                  ),
                                                  Icon(
                                                      Icons
                                                          .arrow_forward_ios_rounded,
                                                      size: 14,
                                                      color: captionColor),
                                                ],
                                              ),
                                              if (desc.isNotEmpty) ...[
                                                const SizedBox(height: 4),
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
                                              const SizedBox(height: 18),

                                              // Progress info & bar
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    '${LocaleService.tr('Tiến độ:', en: 'Progress:')} $progress%',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: subTextColor,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  Text(
                                                    '${LocaleService.tr('Nhiệm vụ:', en: 'Tasks:')} $completed/$total',
                                                    style: TextStyle(
                                                        fontSize: 11,
                                                        color: captionColor),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: LinearProgressIndicator(
                                                  value: progress / 100.0,
                                                  backgroundColor: isDark
                                                      ? Colors.white
                                                          .withOpacity(0.05)
                                                      : Colors.black
                                                          .withOpacity(0.05),
                                                  valueColor:
                                                      const AlwaysStoppedAnimation<
                                                          Color>(themeColor),
                                                  minHeight: 6,
                                                ),
                                              ),
                                              const SizedBox(height: 14),

                                              // Members Stack
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .people_outline_rounded,
                                                          size: 14,
                                                          color: captionColor),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '${members.length + 1} ${LocaleService.tr('thành viên', en: 'members')}',
                                                        style: TextStyle(
                                                            fontSize: 11,
                                                            color:
                                                                captionColor),
                                                      ),
                                                    ],
                                                  ),
                                                  Row(
                                                    children: [
                                                      _buildBadge(
                                                          currentRole,
                                                          _roleColor(
                                                              currentRole)),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        project['status']
                                                                ?.toUpperCase() ??
                                                            'ACTIVE',
                                                        style: const TextStyle(
                                                            fontSize: 9,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: themeColor),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
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
