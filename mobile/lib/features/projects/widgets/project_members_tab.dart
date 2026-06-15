import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';
import 'project_card.dart';
import 'project_shared.dart';

/// Tab thành viên: hiển thị owner, manager, member với tùy chọn đổi role.
class MembersTab extends StatelessWidget {
  final List<dynamic> owners;
  final List<dynamic> managers;
  final List<dynamic> members;
  final bool canInvite;
  final bool canEditRoles;
  final VoidCallback onInvite;
  final Future<void> Function(dynamic user, String role) onRoleChanged;

  const MembersTab({
    super.key,
    required this.owners,
    required this.managers,
    required this.members,
    required this.canInvite,
    required this.canEditRoles,
    required this.onInvite,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        if (canInvite)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onInvite,
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text('Invite member'),
            ),
          ),
        _MemberGroup(
          title: 'Owner',
          users: owners,
          role: 'Owner',
          canEditRoles: false,
          onRoleChanged: onRoleChanged,
        ),
        _MemberGroup(
          title: 'Managers',
          users: managers,
          role: 'Manager',
          canEditRoles: canEditRoles,
          onRoleChanged: onRoleChanged,
        ),
        _MemberGroup(
          title: 'Members',
          users: members,
          role: 'Member',
          canEditRoles: canEditRoles,
          onRoleChanged: onRoleChanged,
        ),
      ],
    );
  }
}

class _MemberGroup extends StatelessWidget {
  final String title;
  final List<dynamic> users;
  final String role;
  final bool canEditRoles;
  final Future<void> Function(dynamic user, String role) onRoleChanged;

  const _MemberGroup({
    required this.title,
    required this.users,
    required this.role,
    required this.canEditRoles,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    if (users.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(title,
              style: TextStyle(
                  color: captionColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2)),
        ),
        ...users.map((user) {
          final name = user is Map<String, dynamic>
              ? ((user['name'] ?? '').toString().isNotEmpty
                  ? user['name'].toString()
                  : (user['email'] ?? 'Member').toString().split('@').first)
              : 'Member';
          final email = user is Map<String, dynamic>
              ? (user['email'] ?? '').toString()
              : '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ProjectDetailCard(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: role == 'Owner'
                        ? const Color(0xFFEAB308)
                        : role == 'Manager'
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF06B6D4),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: TextStyle(
                                color: textColor, fontWeight: FontWeight.w900)),
                        if (email.isNotEmpty)
                          Text(email,
                              style:
                                  TextStyle(color: captionColor, fontSize: 11)),
                      ],
                    ),
                  ),
                  canEditRoles
                      ? _RoleEditButton(
                          user: user,
                          role: role,
                          onRoleChanged: onRoleChanged,
                        )
                      : ProjectStatusPill(
                          label: role,
                          color: role == 'Owner'
                              ? const Color(0xFFEAB308)
                              : role == 'Manager'
                                  ? const Color(0xFF8B5CF6)
                                  : const Color(0xFF06B6D4),
                        ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _RoleEditButton extends StatelessWidget {
  final dynamic user;
  final String role;
  final Future<void> Function(dynamic user, String role) onRoleChanged;

  const _RoleEditButton({
    required this.user,
    required this.role,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        role == 'Manager' ? const Color(0xFF8B5CF6) : const Color(0xFF06B6D4);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () => _showEditRoleDialog(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProjectStatusPill(label: role, color: color),
          const SizedBox(width: 4),
          Icon(Icons.edit_rounded, size: 15, color: color),
        ],
      ),
    );
  }

  void _showEditRoleDialog(BuildContext context) {
    String selectedRole = role == 'Manager' ? 'Manager' : 'Member';
    var saving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = ThemeService.isDarkMode.value;
            final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
            final textColor = ThemeService.getTextColor(isDark);
            final subTextColor = ThemeService.getSubTextColor(isDark);

            return AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Text(
                'Edit role',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose this member role in the project.',
                    style: TextStyle(color: subTextColor, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: const ['Manager', 'Member']
                        .map(
                          (value) => DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setDialogState(() => selectedRole = value);
                            }
                          },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setDialogState(() => saving = true);
                          await onRoleChanged(user, selectedRole);
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
