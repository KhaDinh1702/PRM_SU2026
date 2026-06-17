import 'package:flutter/material.dart';
import '../../../services/theme_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../models/project_model.dart';
import 'project_card.dart';
import 'project_shared.dart';

/// Tab thành viên: hiển thị owner, manager, member với tùy chọn đổi role.
class MembersTab extends StatelessWidget {
  final List<dynamic> owners;
  final List<dynamic> managers;
  final List<dynamic> members;
  final List<dynamic> invited;
  final bool canInvite;
  final bool canEditRoles;
  final VoidCallback onInvite;
  final Future<void> Function(dynamic user, String role) onRoleChanged;

  const MembersTab({
    super.key,
    required this.owners,
    required this.managers,
    required this.members,
    required this.invited,
    required this.canInvite,
    required this.canEditRoles,
    required this.onInvite,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppSizes.paddingM + 4.0),
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
        _MemberGroup(
          title: 'Invited',
          users: invited,
          role: 'Invited',
          canEditRoles: false,
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
          padding: const EdgeInsets.only(top: AppSizes.paddingS, bottom: AppSizes.paddingS),
          child: Text(title,
              style: TextStyle(
                  color: captionColor,
                  fontSize: AppSizes.fontS,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2)),
        ),
        ...users.map((user) {
          String name = 'Member';
          String email = '';

          if (user is ProjectMember) {
            final cleanName = user.name.trim();
            final hasRealName = cleanName.isNotEmpty && cleanName.toLowerCase() != 'member';
            name = hasRealName
                ? cleanName
                : (user.email.isNotEmpty ? user.email.split('@').first : 'Member');
            email = user.email;
          } else if (user is Map) {
            final nameVal = (user['name']?.toString() ?? '').trim();
            final emailVal = (user['email']?.toString() ?? '').trim();
            final hasRealName = nameVal.isNotEmpty && nameVal.toLowerCase() != 'member';
            name = hasRealName
                ? nameVal
                : (emailVal.isNotEmpty ? emailVal.split('@').first : 'Member');
            email = emailVal;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.paddingS + 2.0),
            child: ProjectDetailCard(
              padding: const EdgeInsets.all(AppSizes.paddingS + 5.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: AppSizes.avatarS / 2 + 2.0,
                    backgroundColor: role == 'Owner'
                        ? AppColors.warning
                        : role == 'Manager'
                            ? AppColors.dashboardAccent
                            : role == 'Invited'
                                ? Colors.grey
                                : AppColors.projectAccent,
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingS + 4.0),
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
                                  TextStyle(color: captionColor, fontSize: AppSizes.fontS)),
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
                              ? AppColors.warning
                              : role == 'Manager'
                                  ? AppColors.dashboardAccent
                                  : role == 'Invited'
                                      ? Colors.grey
                                      : AppColors.projectAccent,
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
        role == 'Manager' ? AppColors.dashboardAccent : AppColors.projectAccent;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSizes.radiusRound),
      onTap: () => _showEditRoleDialog(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProjectStatusPill(label: role, color: color),
          const SizedBox(width: AppSizes.paddingXS),
          Icon(Icons.edit_rounded, size: AppSizes.fontM + 1.0, color: color),
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
                borderRadius: BorderRadius.circular(AppSizes.radiusL),
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
                    initialValue: selectedRole,
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
