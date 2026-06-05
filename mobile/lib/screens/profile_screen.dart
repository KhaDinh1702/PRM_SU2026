import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/locale_service.dart';
import 'package:sketchy_design_lang/sketchy_design_lang.dart' as sketchy;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isSaving = false;
  final TextEditingController _usernameController = TextEditingController();

  static const Color themeColor = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    // Ưu tiên lấy từ server để có thông tin mới nhất
    final data = await AuthService.fetchMe() ?? await AuthService.getUserInfo();
    if (mounted) {
      setState(() {
        _userData = data;
        _usernameController.text = data?['username'] ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _changeUsername() async {
    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) return;
    if (newUsername == (_userData?['username'] ?? '')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username không thay đổi!'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isSaving = true);
    final result = await AuthService.changeUsername(newUsername);
    if (mounted) {
      setState(() => _isSaving = false);
      if (result['success']) {
        final remaining = result['changesRemaining'] ?? 0;
        setState(() {
          _userData?['username'] = newUsername;
          if (_userData != null) {
            _userData!['usernameChangesRemaining'] = remaining;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['message']} (còn $remaining lượt đổi tháng này)'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message']}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ThemeService.isDarkMode, LocaleService.languageCode, ThemeService.isSketchyMode]),
      builder: (context, child) {
        final isDark = ThemeService.isDarkMode.value;
        final isSketchy = ThemeService.isSketchyMode.value;
        final textColor = ThemeService.getTextColor(isDark);
        final subTextColor = ThemeService.getSubTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);
        final cardBg = ThemeService.getCardColor(isDark);
        final borderColor = ThemeService.getBorderColor(isDark);

        if (isSketchy) {
          return _buildSketchyLayout(isDark, textColor, subTextColor, captionColor, cardBg, borderColor);
        }

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: themeColor))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        LocaleService.tr('HỒ SƠ CÁ NHÂN', en: 'MY PROFILE'),
                        style: TextStyle(color: captionColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      Text(
                        LocaleService.tr('Tài khoản', en: 'Account'),
                        style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 28),

                      // Avatar + Name Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              children: [
                                // Avatar circle
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeColor.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                      )
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      ((_userData?['username'] ?? _userData?['name'] ?? _userData?['email'] ?? 'U') as String)
                                              .isNotEmpty
                                          ? ((_userData?['username'] ?? _userData?['name'] ?? _userData?['email'] ?? 'U') as String)[0]
                                              .toUpperCase()
                                          : 'U',
                                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _userData?['username']?.isNotEmpty == true
                                      ? '@${_userData!['username']}'
                                      : LocaleService.tr('Chưa đặt username', en: 'No username set'),
                                  style: TextStyle(
                                    color: themeColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _userData?['email'] ?? '',
                                  style: TextStyle(color: subTextColor, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Info cards
                      _infoRow(Icons.person_outline_rounded, LocaleService.tr('Họ tên', en: 'Name'),
                          _userData?['name']?.toString().isNotEmpty == true
                              ? _userData!['name']
                              : LocaleService.tr('Chưa cập nhật', en: 'Not set'),
                          textColor, subTextColor, cardBg, borderColor),
                      const SizedBox(height: 10),
                      _infoRow(Icons.email_outlined, 'Email',
                          _userData?['email'] ?? '', textColor, subTextColor, cardBg, borderColor),
                      const SizedBox(height: 28),

                      // Username change section
                      Text(
                        LocaleService.tr('ĐỔI USERNAME', en: 'CHANGE USERNAME'),
                        style: TextStyle(color: captionColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(height: 12),

                      // Remaining changes indicator
                      Builder(builder: (_) {
                        final remaining = _userData?['usernameChangesRemaining'] ?? 2;
                        final used = 2 - remaining;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: remaining == 0
                                ? Colors.redAccent.withOpacity(0.1)
                                : themeColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: remaining == 0
                                  ? Colors.redAccent.withOpacity(0.3)
                                  : themeColor.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                remaining == 0 ? Icons.block_rounded : Icons.swap_horiz_rounded,
                                color: remaining == 0 ? Colors.redAccent : themeColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  remaining == 0
                                      ? LocaleService.tr('Đã dùng hết 2 lượt đổi tháng này', en: 'Used all 2 changes this month')
                                      : LocaleService.tr(
                                          'Đã đổi $used/2 lần tháng này · Còn $remaining lượt',
                                          en: 'Changed $used/2 times this month · $remaining left'),
                                  style: TextStyle(
                                    color: remaining == 0 ? Colors.redAccent : themeColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 14),

                      // Username text field
                      Builder(builder: (_) {
                        final remaining = _userData?['usernameChangesRemaining'] ?? 2;
                        return Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: _usernameController,
                            enabled: remaining > 0,
                            style: TextStyle(color: textColor, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: LocaleService.tr('Nhập username mới...', en: 'Enter new username...'),
                              hintStyle: TextStyle(color: subTextColor),
                              prefixIcon: Icon(Icons.alternate_email_rounded, color: themeColor, size: 20),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              helperText: LocaleService.tr('3-20 ký tự: a-z, 0-9, dấu gạch dưới', en: '3-20 chars: a-z, 0-9, underscore'),
                              helperStyle: TextStyle(color: captionColor, fontSize: 11),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 14),

                      // Save button
                      Builder(builder: (_) {
                        final remaining = _userData?['usernameChangesRemaining'] ?? 2;
                        final canChange = remaining > 0 && !_isSaving;
                        return GestureDetector(
                          onTap: canChange ? _changeUsername : null,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 54,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: canChange
                                  ? const LinearGradient(
                                      colors: [Color(0xFF8B5CF6), Color(0xFF06B6D4)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : LinearGradient(
                                      colors: [Colors.grey.withOpacity(0.3), Colors.grey.withOpacity(0.3)],
                                    ),
                              boxShadow: canChange
                                  ? [BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))]
                                  : [],
                            ),
                            alignment: Alignment.center,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22, height: 22,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                  )
                                : Text(
                                    LocaleService.tr('Lưu Username', en: 'Save Username'),
                                    style: TextStyle(
                                      color: canChange ? Colors.white : subTextColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSketchyLayout(bool isDark, Color textColor, Color subTextColor, Color captionColor, Color cardBg, Color borderColor) {
    final remainingChanges = _userData?['usernameChangesRemaining'] ?? 2;
    final usedChanges = 2 - remainingChanges;

    return sketchy.SketchyScaffold(
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: themeColor))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  sketchy.SketchyText(
                    LocaleService.tr('HỒ SƠ CÁ NHÂN', en: 'MY PROFILE'),
                    style: TextStyle(color: captionColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  sketchy.SketchyText(
                    LocaleService.tr('Tài khoản', en: 'Account'),
                    style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 28),

                  // Avatar + Name Card vẽ tay
                  sketchy.SketchyCard(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Avatar circle vẽ tay
                          sketchy.SketchyCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                ((_userData?['username'] ?? _userData?['name'] ?? _userData?['email'] ?? 'U') as String).isNotEmpty
                                    ? ((_userData?['username'] ?? _userData?['name'] ?? _userData?['email'] ?? 'U') as String)[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(color: textColor, fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          sketchy.SketchyText(
                            _userData?['username']?.isNotEmpty == true
                                ? '@${_userData!['username']}'
                                : LocaleService.tr('Chưa đặt username', en: 'No username set'),
                            style: const TextStyle(
                              color: themeColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          sketchy.SketchyText(
                            _userData?['email'] ?? '',
                            style: TextStyle(color: subTextColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Info rows vẽ tay
                  _buildSketchyInfoRow(Icons.person_outline_rounded, LocaleService.tr('Họ tên', en: 'Name'),
                      _userData?['name']?.toString().isNotEmpty == true
                          ? _userData!['name']
                          : LocaleService.tr('Chưa cập nhật', en: 'Not set'),
                      textColor, subTextColor),
                  const SizedBox(height: 10),
                  _buildSketchyInfoRow(Icons.email_outlined, 'Email',
                      _userData?['email'] ?? '', textColor, subTextColor),
                  const SizedBox(height: 20),

                  // Sketchy Theme config card
                  sketchy.SketchyCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.gesture_rounded, color: themeColor, size: 24),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                sketchy.SketchyText(
                                  LocaleService.tr('Giao diện vẽ tay', en: 'Sketchy UI Theme'),
                                  style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                                sketchy.SketchyText(
                                  LocaleService.tr('Đang kích hoạt', en: 'Currently active'),
                                  style: TextStyle(color: subTextColor, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          sketchy.SketchyButton(
                            onPressed: () => ThemeService.toggleSketchyMode(),
                            child: sketchy.SketchyText(
                              LocaleService.tr('Tắt', en: 'Turn Off'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Username change section vẽ tay
                  sketchy.SketchyText(
                    LocaleService.tr('ĐỔI USERNAME', en: 'CHANGE USERNAME'),
                    style: TextStyle(color: captionColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 12),

                  // Remaining changes indicator vẽ tay
                  sketchy.SketchyCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            remainingChanges == 0 ? Icons.block_rounded : Icons.swap_horiz_rounded,
                            color: remainingChanges == 0 ? Colors.redAccent : themeColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: sketchy.SketchyText(
                              remainingChanges == 0
                                  ? LocaleService.tr('Đã dùng hết 2 lượt đổi tháng này', en: 'Used all 2 changes this month')
                                  : LocaleService.tr(
                                      'Đã đổi $usedChanges/2 lần tháng này · Còn $remainingChanges lượt',
                                      en: 'Changed $usedChanges/2 times this month · $remainingChanges left'),
                              style: TextStyle(
                                color: remainingChanges == 0 ? Colors.redAccent : themeColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Username text field vẽ tay
                  sketchy.SketchyCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: sketchy.SketchyTextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: LocaleService.tr('Nhập username mới...', en: 'Enter new username...'),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Save button vẽ tay
                  _isSaving
                      ? const Center(child: CircularProgressIndicator(color: themeColor))
                      : sketchy.SketchyButton(
                          onPressed: remainingChanges > 0 ? _changeUsername : null,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: sketchy.SketchyText(
                                LocaleService.tr('Lưu Username', en: 'Save Username'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildSketchyInfoRow(IconData icon, String label, String value, Color textColor, Color subTextColor) {
    return sketchy.SketchyCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: themeColor, size: 20),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sketchy.SketchyText(label, style: TextStyle(fontSize: 11, color: subTextColor, fontWeight: FontWeight.w600)),
                sketchy.SketchyText(value, style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      Color textColor, Color subTextColor, Color cardBg, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: subTextColor, fontWeight: FontWeight.w600)),
              Text(value, style: TextStyle(fontSize: 14, color: textColor, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
