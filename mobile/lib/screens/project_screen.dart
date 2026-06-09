library project_screen;

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/locale_service.dart';
import '../widgets/premium_widgets.dart';
import '../widgets/chat_bottom_sheet.dart';

part '../features/projects/project_screen_sections.dart';
part '../features/projects/project_screen_helpers.dart';
part '../features/projects/project_screen_components.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  bool _isLoading = true;
  String? _projectLoadError;
  List<dynamic> _projects = [];
  List<dynamic> _allUsers = [];
  bool _isLoadingUsers = false;
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
  String _projectSearchQuery = '';
  String _projectTab = 'All';
  String _roleFilter = 'All';
  String _typeFilter = 'All';
  String _sortBy = 'Recent';
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
              content: Text(LocaleService.tr(
                  'Ãƒâ€žÃ‚ÂÃƒÆ’Ã‚Â£ xÃƒÆ’Ã‚Â³a dÃƒÂ¡Ã‚Â»Ã‚Â± ÃƒÆ’Ã‚Â¡n thÃƒÆ’Ã‚Â nh cÃƒÆ’Ã‚Â´ng!',
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
            LocaleService.tr('XÃƒÆ’Ã‚Â³a thÃƒÂ¡Ã‚ÂºÃ‚Â¥t bÃƒÂ¡Ã‚ÂºÃ‚Â¡i',
                en: 'Deletion failed'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${LocaleService.tr('LÃƒÂ¡Ã‚Â»Ã¢â‚¬â€i khi xÃƒÆ’Ã‚Â³a dÃƒÂ¡Ã‚Â»Ã‚Â± ÃƒÆ’Ã‚Â¡n:', en: 'Error deleting project:')} $e'),
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
                    LocaleService.tr('XÃƒÆ’Ã¢â‚¬Å“A DÃƒÂ¡Ã‚Â»Ã‚Â° ÃƒÆ’Ã‚ÂN?',
                        en: 'DELETE PROJECT?'),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 1.2),
                  ),
                ),
              ],
            ),
            content: Text(
              '${LocaleService.tr('BÃƒÂ¡Ã‚ÂºÃ‚Â¡n cÃƒÆ’Ã‚Â³ chÃƒÂ¡Ã‚ÂºÃ‚Â¯c chÃƒÂ¡Ã‚ÂºÃ‚Â¯n muÃƒÂ¡Ã‚Â»Ã¢â‚¬Ëœn xÃƒÆ’Ã‚Â³a dÃƒÂ¡Ã‚Â»Ã‚Â± ÃƒÆ’Ã‚Â¡n', en: 'Are you sure you want to delete project')} "$projectName"?\n${LocaleService.tr('HÃƒÆ’Ã‚Â nh Ãƒâ€žÃ¢â‚¬ËœÃƒÂ¡Ã‚Â»Ã¢â€žÂ¢ng nÃƒÆ’Ã‚Â y sÃƒÂ¡Ã‚ÂºÃ‚Â½ xÃƒÆ’Ã‚Â³a toÃƒÆ’Ã‚Â n bÃƒÂ¡Ã‚Â»Ã¢â€žÂ¢ task vÃƒÆ’Ã‚Â  khÃƒÆ’Ã‚Â´ng thÃƒÂ¡Ã‚Â»Ã†â€™ khÃƒÆ’Ã‚Â´i phÃƒÂ¡Ã‚Â»Ã‚Â¥c!', en: 'This action will delete all tasks and cannot be undone!')}',
              style: TextStyle(color: subTextColor, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  LocaleService.tr('HÃƒÂ¡Ã‚Â»Ã‚Â§y', en: 'Cancel'),
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
                  LocaleService.tr('XÃƒÆ’Ã‚Â³a', en: 'Delete'),
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
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _projectLoadError = null;
    });
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Missing login token');
      }

      final response = await http.get(
        Uri.parse('https://prm-tan.vercel.app/api/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (mounted) {
          setState(() {
            _projects = _normalizeProjectResponse(decoded);
            _isLoading = false;
            _projectLoadError = null;
          });
        }
      } else {
        var errorMessage = 'Could not load projects';
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic> && data['error'] != null) {
            errorMessage = data['error'].toString();
          }
        } catch (_) {}
        throw Exception('HTTP ${response.statusCode}: $errorMessage');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _projects = [];
          _projectLoadError = e.toString().replaceFirst('Exception: ', '');
        });
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
                  'Ãƒâ€žÃ‚ÂÃƒÆ’Ã‚Â£ khÃƒÂ¡Ã‚Â»Ã…Â¸i tÃƒÂ¡Ã‚ÂºÃ‚Â¡o dÃƒÂ¡Ã‚Â»Ã‚Â± ÃƒÆ’Ã‚Â¡n nhÃƒÆ’Ã‚Â³m thÃƒÆ’Ã‚Â nh cÃƒÆ’Ã‚Â´ng!',
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

  Future<void> _updateProject(
    String projectId,
    Map<String, dynamic> payload,
  ) async {
    try {
      final token = await AuthService.getToken();
      final response = await http
          .put(
            Uri.parse('https://prm-tan.vercel.app/api/projects/$projectId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        await _loadProjects();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Project updated successfully.'),
              backgroundColor: Color(0xFF06B6D4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final data = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      throw Exception(data['error'] ?? 'Update failed');
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
              content: Text(LocaleService.tr(
                  'Ãƒâ€žÃ‚ÂÃƒÆ’Ã‚Â£ gÃƒÂ¡Ã‚Â»Ã‚Â­i lÃƒÂ¡Ã‚Â»Ã‚Âi mÃƒÂ¡Ã‚Â»Ã‚Âi tham gia dÃƒÂ¡Ã‚Â»Ã‚Â± ÃƒÆ’Ã‚Â¡n!',
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
                errorText.contains('mÃƒÂ¡Ã‚Â»Ã‚Âi') ||
                errorText.contains('moi'))) {
          _memberEmailController.clear();
          return fallbackUserId;
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ??
                  LocaleService.tr(
                      'CÃƒÆ’Ã‚Â³ lÃƒÂ¡Ã‚Â»Ã¢â‚¬â€i xÃƒÂ¡Ã‚ÂºÃ‚Â£y ra.',
                      en: 'An error occurred.')),
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
              LocaleService.tr(
                  'TÃƒÂ¡Ã‚ÂºÃ‚Â O DÃƒÂ¡Ã‚Â»Ã‚Â° ÃƒÆ’Ã‚ÂN MÃƒÂ¡Ã‚Â»Ã…Â¡I',
                  en: 'CREATE NEW PROJECT'),
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
                  label: LocaleService.tr(
                      'TÃƒÆ’Ã‚Âªn dÃƒÂ¡Ã‚Â»Ã‚Â± ÃƒÆ’Ã‚Â¡n *',
                      en: 'Project name *'),
                  hintText: LocaleService.tr(
                      'NhÃƒÂ¡Ã‚ÂºÃ‚Â­p tÃƒÆ’Ã‚Âªn dÃƒÂ¡Ã‚Â»Ã‚Â± ÃƒÆ’Ã‚Â¡n...',
                      en: 'Enter project name...'),
                  prefixIcon: Icons.folder_rounded,
                ),
                const SizedBox(height: 14),
                PremiumInputField(
                  controller: _descController,
                  label: LocaleService.tr(
                      'MÃƒÆ’Ã‚Â´ tÃƒÂ¡Ã‚ÂºÃ‚Â£ dÃƒÂ¡Ã‚Â»Ã‚Â± ÃƒÆ’Ã‚Â¡n',
                      en: 'Project description'),
                  hintText: LocaleService.tr(
                      'NhÃƒÂ¡Ã‚ÂºÃ‚Â­p mÃƒÆ’Ã‚Â´ tÃƒÂ¡Ã‚ÂºÃ‚Â£ dÃƒÂ¡Ã‚Â»Ã‚Â± ÃƒÆ’Ã‚Â¡n...',
                      en: 'Enter project description...'),
                  prefixIcon: Icons.description_outlined,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(LocaleService.tr('HÃƒÂ¡Ã‚Â»Ã‚Â§y', en: 'Cancel'),
                    style: TextStyle(
                        color: captionColor, fontWeight: FontWeight.bold)),
              ),
              PremiumButton(
                onPressed: () {
                  _createProject();
                  Navigator.pop(context);
                },
                backgroundColor: const Color(0xFF06B6D4),
                child: Text(LocaleService.tr('TÃƒÂ¡Ã‚ÂºÃ‚Â¡o', en: 'Create'),
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
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
              content: Text(LocaleService.tr(
                  'Ãƒâ€žÃ‚ÂÃƒÆ’Ã‚Â£ phÃƒÆ’Ã‚Â¢n task thÃƒÆ’Ã‚Â nh cÃƒÆ’Ã‚Â´ng!',
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
                '${LocaleService.tr('LÃƒÂ¡Ã‚Â»Ã¢â‚¬â€i khi phÃƒÆ’Ã‚Â¢n task:', en: 'Error assigning task:')} $e'),
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
              content: Text(LocaleService.tr(
                  'Ãƒâ€žÃ‚ÂÃƒÆ’Ã‚Â£ cÃƒÂ¡Ã‚ÂºÃ‚Â­p nhÃƒÂ¡Ã‚ÂºÃ‚Â­t task thÃƒÆ’Ã‚Â nh cÃƒÆ’Ã‚Â´ng!',
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
              'Backend chÃƒâ€ Ã‚Â°a cÃƒÂ¡Ã‚ÂºÃ‚Â­p nhÃƒÂ¡Ã‚ÂºÃ‚Â­t API sÃƒÂ¡Ã‚Â»Ã‚Â­a task dÃƒÂ¡Ã‚Â»Ã‚Â± ÃƒÆ’Ã‚Â¡n. CÃƒÂ¡Ã‚ÂºÃ‚Â§n deploy backend mÃƒÂ¡Ã‚Â»Ã¢â‚¬Âºi.',
              en: 'Project task edit API is not deployed yet. Please deploy the updated backend.');
        }
        return (data['error'] ?? 'Cannot update task').toString();
      }
      return 'Cannot update task';
    } catch (e) {
      return '${LocaleService.tr('LÃƒÂ¡Ã‚Â»Ã¢â‚¬â€i khi cÃƒÂ¡Ã‚ÂºÃ‚Â­p nhÃƒÂ¡Ã‚ÂºÃ‚Â­t task:', en: 'Error updating task:')} $e';
    }
  }

  // ignore: unused_element
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

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF06B6D4);

    return ListenableBuilder(
      listenable: Listenable.merge(
          [ThemeService.isDarkMode, LocaleService.languageCode]),
      builder: (context, child) {
        final isDark = ThemeService.isDarkMode.value;
        final textColor = ThemeService.getTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);
        final visibleProjectModels =
            _visibleProjects.map(_projectCardModel).toList();
        final attentionProjectModels =
            _attentionProjects.map(_projectCardModel).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TEAM COLLABORATION',
                            style: TextStyle(
                              color: captionColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Team Projects',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PremiumButton.icon(
                      onPressed: _showCreateProjectDialog,
                      icon: Icons.add,
                      label: 'New',
                      backgroundColor: themeColor,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ProjectSearchBar(
                  controller: _projectSearchController,
                  onChanged: (value) {
                    setState(() => _projectSearchQuery = value);
                  },
                  onFilterTap: _showProjectFilterBottomSheet,
                ),
                const SizedBox(height: 12),
                ProjectSummary(
                  totalProjects: _projects.length,
                  activeProjects: _activeProjectCount,
                  attentionProjects: _attentionProjects.length,
                ),
                const SizedBox(height: 14),
                ProjectTabs(
                  tabs: _projectFilterOptions,
                  selectedTab: _projectTab,
                  onChanged: (tab) {
                    setState(() => _projectTab = tab);
                  },
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _isLoading
                      ? ListView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: 4,
                          itemBuilder: (context, index) => const Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: ShimmerLoading(
                              width: double.infinity,
                              height: 150,
                              borderRadius: 18,
                            ),
                          ),
                        )
                      : _projectLoadError != null
                          ? FadeInSlide(
                              delayMs: 100,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.cloud_off_rounded,
                                      size: 54,
                                      color: Colors.redAccent.withOpacity(0.75),
                                    ),
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24),
                                      child: Text(
                                        _projectLoadError!,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: captionColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    PremiumButton.icon(
                                      onPressed: _loadProjects,
                                      icon: Icons.refresh_rounded,
                                      label: 'Retry',
                                      backgroundColor: themeColor,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _projects.isEmpty
                              ? FadeInSlide(
                                  delayMs: 100,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.dns_outlined,
                                          size: 54,
                                          color: captionColor.withOpacity(0.4),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No projects yet.',
                                          style: TextStyle(
                                            color: captionColor,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : visibleProjectModels.isEmpty
                                  ? FadeInSlide(
                                      delayMs: 100,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.filter_alt_off_rounded,
                                              size: 54,
                                              color:
                                                  captionColor.withOpacity(0.4),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'No projects match your filters',
                                              style: TextStyle(
                                                color: captionColor,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            TextButton(
                                              onPressed: _clearProjectFilters,
                                              child: const Text('Show all'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: _loadProjects,
                                      color: themeColor,
                                      child: ListView(
                                        physics: const BouncingScrollPhysics(),
                                        children: [
                                          if (_projectTab == 'All' &&
                                              _projectSearchQuery
                                                  .trim()
                                                  .isEmpty) ...[
                                            NeedsAttentionSection(
                                              projects: attentionProjectModels,
                                              onProjectTap: (project) =>
                                                  _showProjectDetails(
                                                project.raw
                                                    as Map<String, dynamic>,
                                              ),
                                            ),
                                            if (attentionProjectModels
                                                .isNotEmpty)
                                              const SizedBox(height: 20),
                                          ],
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                _projectTab == 'All'
                                                    ? 'All Projects'
                                                    : '$_projectTab Projects',
                                                style: TextStyle(
                                                  color: textColor,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              Text(
                                                '${visibleProjectModels.length}/${_projects.length}',
                                                style: TextStyle(
                                                  color: captionColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          ...visibleProjectModels
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            final project = entry.value;
                                            return FadeInSlide(
                                              delayMs: entry.key * 50,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 12.0),
                                                child: ProjectCard(
                                                  project: project,
                                                  onTap: () =>
                                                      _showProjectDetails(
                                                    project.raw
                                                        as Map<String, dynamic>,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                        ],
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
