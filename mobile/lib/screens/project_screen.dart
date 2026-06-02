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

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _memberEmailController.dispose();
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
        
        List<dynamic> loadedProjects = [];
        for (var p in rawProjects) {
          final pId = p['_id'];
          final detailResponse = await http.get(
            Uri.parse('https://prm-tan.vercel.app/api/projects/$pId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ).timeout(const Duration(seconds: 10));

          if (detailResponse.statusCode == 200) {
            loadedProjects.add(jsonDecode(detailResponse.body));
          } else {
            loadedProjects.add({'project': p, 'stats': {'totalTasks': 0, 'completedTasks': 0, 'progressPercentage': 0}});
          }
        }

        if (mounted) {
          setState(() {
            _projects = loadedProjects;
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
      final response = await http.post(
        Uri.parse('https://prm-tan.vercel.app/api/projects'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'description': _descController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        _nameController.clear();
        _descController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleService.tr('Đã khởi tạo dự án nhóm thành công! 🚀', en: 'Project created successfully! 🚀')),
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

  Future<void> _addMember(String projectId) async {
    final email = _memberEmailController.text.trim();
    if (email.isEmpty) return;

    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('https://prm-tan.vercel.app/api/projects/$projectId/members'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': email}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        _memberEmailController.clear();
        _loadProjects();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(LocaleService.tr('Đã thêm thành viên mới thành công! 🌟', en: 'Member added successfully! 🌟')),
              backgroundColor: Colors.indigo,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['error'] ?? LocaleService.tr('Có lỗi xảy ra.', en: 'An error occurred.')),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {}
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
              side: BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
            ),
            title: Text(
              LocaleService.tr('TẠO DỰ ÁN MỚI', en: 'CREATE NEW PROJECT'),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor, letterSpacing: 1.5),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PremiumInputField(
                  controller: _nameController,
                  label: LocaleService.tr('Tên dự án *', en: 'Project name *'),
                  hintText: LocaleService.tr('Nhập tên dự án...', en: 'Enter project name...'),
                  prefixIcon: Icons.folder_rounded,
                ),
                const SizedBox(height: 14),
                PremiumInputField(
                  controller: _descController,
                  label: LocaleService.tr('Mô tả dự án', en: 'Project description'),
                  hintText: LocaleService.tr('Nhập mô tả dự án...', en: 'Enter project description...'),
                  prefixIcon: Icons.description_outlined,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(LocaleService.tr('Hủy', en: 'Cancel'), style: TextStyle(color: captionColor, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton(
                onPressed: () {
                  _createProject();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF06B6D4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(LocaleService.tr('Tạo', en: 'Create'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProjectDetails(Map<String, dynamic> projectData) {
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
        final cardBgColor = ThemeService.getCardColor(isDark);
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
                      color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
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
                        project['name'] ?? LocaleService.tr('Dự án không tên', en: 'Untitled project'),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (context) => ChatBottomSheet(
                            projectId: project['_id'],
                            projectName: project['name'] ?? LocaleService.tr('Dự án không tên', en: 'Untitled project'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, size: 16, color: Colors.white),
                      label: Text(LocaleService.tr('Chat', en: 'Chat'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        elevation: 4,
                        shadowColor: const Color(0xFF06B6D4).withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  project['description']?.toString().isNotEmpty == true ? project['description'] : LocaleService.tr('Không có mô tả chi tiết.', en: 'No detailed description.'),
                  style: TextStyle(fontSize: 14, color: subTextColor),
                ),
                const SizedBox(height: 24),

                // Members Title & Add Member
                Text(LocaleService.tr('THÀNH VIÊN DỰ ÁN', en: 'PROJECT MEMBERS'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: captionColor, letterSpacing: 2)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PremiumInputField(
                        controller: _memberEmailController,
                        label: LocaleService.tr('Mời thành viên', en: 'Invite member'),
                        hintText: LocaleService.tr('Nhập email thành viên...', en: 'Enter member email...'),
                        prefixIcon: Icons.mail_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        _addMember(project['_id']);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      child: Text(LocaleService.tr('Mời', en: 'Invite'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                                  color: const Color(0xFFEAB308).withOpacity(isDark ? 0.05 : 0.03),
                                  blurRadius: 10,
                                )
                              ],
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFEAB308),
                                    radius: 18,
                                    child: Icon(Icons.star_rounded, size: 18, color: Colors.white),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              owner['name']?.toString().isNotEmpty == true ? owner['name'] : owner['email'].split('@')[0],
                                              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEAB308).withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(LocaleService.tr('CHỦ DỰ ÁN', en: 'OWNER'), style: const TextStyle(color: Color(0xFFEAB308), fontSize: 8, fontWeight: FontWeight.w900)),
                                            )
                                          ],
                                        ),
                                        Text(owner['email'], style: TextStyle(fontSize: 12, color: captionColor)),
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
                                  child: Icon(Icons.person_rounded, size: 18, color: Colors.white),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member['name']?.toString().isNotEmpty == true ? member['name'] : member['email'].split('@')[0],
                                      style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                                    ),
                                    Text(member['email'], style: TextStyle(fontSize: 12, color: captionColor)),
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

                      final alreadyMember =
                          members.any((m) => m['_id'] == user['_id']) ||
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
                                  backgroundColor: const Color(0xFF06B6D4),
                                  backgroundImage:
                                  user['profile']?['avatarUrl'] != null &&
                                      user['profile']['avatarUrl']
                                          .toString()
                                          .isNotEmpty
                                      ? NetworkImage(
                                    user['profile']['avatarUrl'],
                                  )
                                      : null,
                                  child:
                                  user['profile']?['avatarUrl'] == null ||
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
                                        user['name']?.toString().isNotEmpty ==
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
                                    : ElevatedButton(
                                  onPressed: () async {
                                    _memberEmailController.text =
                                    user['email'];

                                    await _addMember(project['_id']);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFF06B6D4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    LocaleService.tr(
                                      'Thêm',
                                      en: 'Add',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
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

    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.isDarkMode,
      builder: (context, isDark, child) {
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
                          LocaleService.tr('HỢP TÁC ĐỒNG ĐỘI', en: 'TEAM COLLABORATION'),
                          style: TextStyle(color: captionColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                        Text(
                          LocaleService.tr('Dự Án Nhóm', en: 'Team Projects'),
                          style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _showCreateProjectDialog,
                      icon: const Icon(Icons.add, size: 18, color: Colors.white),
                      label: Text(LocaleService.tr('Tạo dự án', en: 'New project'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
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
                            child: ShimmerLoading(width: double.infinity, height: 160, borderRadius: 24),
                          ),
                        )
                      : _projects.isEmpty
                          ? FadeInSlide(
                              delayMs: 100,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.dns_outlined, size: 54, color: captionColor.withOpacity(0.4)),
                                    const SizedBox(height: 12),
                                    Text(LocaleService.tr('Chưa có dự án nào.', en: 'No projects yet.'), style: TextStyle(color: captionColor, fontSize: 14)),
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
                                  
                                  final name = project['name'] ?? LocaleService.tr('Dự án không tên', en: 'Untitled project');
                                  final desc = project['description'] ?? '';
                                  final total = stats['totalTasks'] ?? 0;
                                  final completed = stats['completedTasks'] ?? 0;
                                  final progress = stats['progressPercentage'] ?? 0;
                                  final members = project['members'] as List<dynamic>? ?? [];

                                  return FadeInSlide(
                                    delayMs: index * 80,
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 12.0),
                                      child: GestureDetector(
                                        onTap: () => _showProjectDetails(projectData),
                                        child: GlassCard(
                                          borderRadius: 24,
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                                  ),
                                                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: captionColor),
                                                ],
                                              ),
                                              if (desc.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  desc,
                                                  style: TextStyle(fontSize: 12, color: subTextColor),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                              const SizedBox(height: 18),

                                              // Progress info & bar
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    '${LocaleService.tr('Tiến độ:', en: 'Progress:')} $progress%',
                                                    style: TextStyle(fontSize: 11, color: subTextColor, fontWeight: FontWeight.bold),
                                                  ),
                                                  Text(
                                                    '${LocaleService.tr('Nhiệm vụ:', en: 'Tasks:')} $completed/$total',
                                                    style: TextStyle(fontSize: 11, color: captionColor),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(10),
                                                child: LinearProgressIndicator(
                                                  value: progress / 100.0,
                                                  backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                                  valueColor: const AlwaysStoppedAnimation<Color>(themeColor),
                                                  minHeight: 6,
                                                ),
                                              ),
                                              const SizedBox(height: 14),

                                              // Members Stack
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.people_outline_rounded, size: 14, color: captionColor),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        '${members.length + 1} ${LocaleService.tr('thành viên', en: 'members')}',
                                                        style: TextStyle(fontSize: 11, color: captionColor),
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    project['status']?.toUpperCase() ?? 'ACTIVE',
                                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: themeColor),
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
