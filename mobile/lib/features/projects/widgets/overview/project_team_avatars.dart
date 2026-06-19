import 'package:flutter/material.dart';

import '../../../../services/theme_service.dart';
import '../../models/project_model.dart';

class ProjectTeamAvatars extends StatelessWidget {
  final List<ProjectMember> members;
  final Map<String, String> memberRoles;
  final VoidCallback? onInvite;
  final VoidCallback? onManage;

  const ProjectTeamAvatars({
    super.key,
    required this.members,
    required this.memberRoles,
    this.onInvite,
    this.onManage,
  });

  String _roleFor(ProjectMember member) =>
      memberRoles[member.id] ?? 'Member';

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);
    final primary = ThemeService.getPrimaryColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Team Members',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (onManage != null)
              TextButton(
                onPressed: onManage,
                child: Text('Manage',
                    style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: members.length + (onInvite != null ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (onInvite != null && index == members.length) {
                return _InviteAvatar(onTap: onInvite!);
              }

              final member = members[index];
              final initial = member.name.isNotEmpty
                  ? member.name[0].toUpperCase()
                  : member.email.isNotEmpty
                      ? member.email[0].toUpperCase()
                      : '?';

              return SizedBox(
                width: 76,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: primary,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      member.name.isNotEmpty
                          ? member.name.split(' ').first
                          : member.email.split('@').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      _roleFor(member),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: captionColor, fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InviteAvatar extends StatelessWidget {
  final VoidCallback onTap;

  const _InviteAvatar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeService.isDarkMode.value;
    final primary = ThemeService.getPrimaryColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Icon(Icons.person_add_alt_rounded, color: primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Invite',
              style: TextStyle(
                color: primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Member',
              style: TextStyle(color: captionColor, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
