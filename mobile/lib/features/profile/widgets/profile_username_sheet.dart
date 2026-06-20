import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/locale_service.dart';
import '../../../services/theme_service.dart';
import '../../auth/providers/auth_provider.dart';

/// Bottom sheet that lets the user change their username.
///
/// Owns its own [TextEditingController] + saving state so the surrounding
/// Profile screen stays stateless about this rare action. Returns `true`
/// when a save succeeded so the caller can refresh.
class ProfileUsernameSheet extends StatefulWidget {
  const ProfileUsernameSheet({super.key});

  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileUsernameSheet(),
    );
  }

  @override
  State<ProfileUsernameSheet> createState() => _ProfileUsernameSheetState();
}

class _ProfileUsernameSheetState extends State<ProfileUsernameSheet> {
  late final TextEditingController _controller;
  bool _saving = false;
  String? _error;

  static final RegExp _validRegex = RegExp(r'^[a-z0-9_]{3,20}$');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<AuthProvider>().username,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String value, String currentUsername) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return LocaleService.tr('Username không được trống.',
          en: 'Username cannot be empty.');
    }
    if (trimmed == currentUsername) {
      return LocaleService.tr('Username không thay đổi.',
          en: 'Username has not changed.');
    }
    if (!_validRegex.hasMatch(trimmed)) {
      return LocaleService.tr(
          '3-20 ký tự, chỉ a-z, 0-9 và gạch dưới.',
          en: '3-20 chars, only a-z, 0-9 and underscore.');
    }
    return null;
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final error = _validate(_controller.text, auth.username);
    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await auth.changeUsername(_controller.text.trim());
    if (!mounted) return;

    if (result['success'] == true) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']?.toString() ??
              LocaleService.tr('Đổi username thành công.',
                  en: 'Username updated.')),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _saving = false;
        _error = result['message']?.toString() ??
            LocaleService.tr('Có lỗi xảy ra.', en: 'Something went wrong.');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final subTextColor = ThemeService.getSubTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final accent = ThemeService.getPrimaryColor(isDark);

    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final auth = context.watch<AuthProvider>();
    final remaining = auth.usernameChangesRemaining;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: dialogBg.withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border.all(color: borderColor),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: captionColor.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    LocaleService.tr('Đổi username', en: 'Change username'),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    LocaleService.tr(
                      'Còn $remaining/2 lượt đổi tháng này.',
                      en: '$remaining/2 changes left this month.',
                    ),
                    style: TextStyle(color: subTextColor, fontSize: 12),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _controller,
                    enabled: !_saving && remaining > 0,
                    autofocus: true,
                    onChanged: (_) {
                      if (_error != null) setState(() => _error = null);
                    },
                    style: TextStyle(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      labelText:
                          LocaleService.tr('Username', en: 'Username'),
                      hintText: 'myhandle',
                      prefixIcon:
                          Icon(Icons.alternate_email_rounded, color: accent),
                      helperText: LocaleService.tr(
                        '3-20 ký tự, a-z, 0-9, gạch dưới',
                        en: '3-20 chars, a-z, 0-9, underscore',
                      ),
                      helperStyle:
                          TextStyle(color: captionColor, fontSize: 11),
                      errorText: _error,
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: accent, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Spacer(),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: Text(
                          LocaleService.tr('Hủy', en: 'Cancel'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 6),
                      FilledButton.icon(
                        onPressed:
                            (_saving || remaining == 0) ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(_saving
                            ? LocaleService.tr('Đang lưu…', en: 'Saving…')
                            : LocaleService.tr('Lưu', en: 'Save')),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
