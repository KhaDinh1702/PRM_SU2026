import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';

/// Red-tinted logout button. Always asks for confirmation before firing
/// `onLogout` so a single mis-tap can't sign the user out.
class ProfileLogoutButton extends StatelessWidget {
  final VoidCallback? onLogout;

  const ProfileLogoutButton({super.key, required this.onLogout});

  Future<void> _confirmAndLogout(BuildContext context) async {
    if (onLogout == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleService.tr('Đăng xuất?', en: 'Log out?')),
        content: Text(LocaleService.tr(
          'Bạn sẽ cần đăng nhập lại để tiếp tục dùng FlowMate.',
          en: 'You will need to sign in again to keep using FlowMate.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(LocaleService.tr('Hủy', en: 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(LocaleService.tr('Đăng xuất', en: 'Log out')),
          ),
        ],
      ),
    );
    if (confirm == true) onLogout!();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onLogout == null ? null : () => _confirmAndLogout(context),
        icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
        label: Text(
          LocaleService.tr('Đăng xuất', en: 'Log out'),
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.redAccent.withValues(alpha: 0.08),
          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.32)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }
}
