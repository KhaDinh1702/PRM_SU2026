import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../services/theme_service.dart';
import '../../models/project_type.dart';
import '../../providers/project_create_provider.dart';
import 'section_header.dart';

/// Invite-by-email list. Hidden when the selected type is not collaborative
/// (Personal).
class CreateProjectMembersSection extends StatefulWidget {
  const CreateProjectMembersSection({super.key});

  @override
  State<CreateProjectMembersSection> createState() =>
      _CreateProjectMembersSectionState();
}

class _CreateProjectMembersSectionState
    extends State<CreateProjectMembersSection> {
  final TextEditingController _controller = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(ProjectCreateProvider provider) {
    final value = _controller.text.trim().toLowerCase();
    if (value.isEmpty) return;
    if (!_emailRegex.hasMatch(value)) {
      setState(() => _localError = 'Invalid email address');
      return;
    }
    if (provider.draft.inviteEmails.contains(value)) {
      setState(() => _localError = 'Already added');
      return;
    }
    provider.addInviteEmail(value);
    _controller.clear();
    setState(() => _localError = null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectCreateProvider>();
    final meta = ProjectTypeMeta.of(provider.draft.type);
    if (!meta.collaborative) return const SizedBox.shrink();

    final isDark = ThemeService.isDarkMode.value;
    final captionColor = ThemeService.getCaptionColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CreateProjectSectionHeader(
          icon: Icons.group_add_rounded,
          title: 'Members',
          subtitle: 'Invite teammates by email — optional.',
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) => _add(provider),
                style: TextStyle(color: textColor, fontSize: AppSizes.fontM),
                decoration: InputDecoration(
                  hintText: 'name@email.com',
                  errorText: _localError,
                  hintStyle: TextStyle(color: captionColor),
                  isDense: true,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.black.withValues(alpha: 0.03),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingM - 4,
                    vertical: AppSizes.paddingS + 4,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.paddingS),
            SizedBox(
              height: 44,
              child: FilledButton.icon(
                onPressed: () => _add(provider),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
                style: FilledButton.styleFrom(
                  backgroundColor: meta.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusM),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (provider.draft.inviteEmails.isNotEmpty) ...[
          const SizedBox(height: AppSizes.paddingS + 4),
          Wrap(
            spacing: AppSizes.paddingS,
            runSpacing: AppSizes.paddingS,
            children: [
              for (final email in provider.draft.inviteEmails)
                Chip(
                  label: Text(email),
                  labelStyle: TextStyle(
                    color: textColor,
                    fontSize: AppSizes.fontS + 1,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: meta.color.withValues(alpha: 0.14),
                  side: BorderSide(color: meta.color.withValues(alpha: 0.45)),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.radiusRound),
                  ),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: () => provider.removeInviteEmail(email),
                ),
            ],
          ),
        ],
      ],
    );
  }

  static final RegExp _emailRegex =
      RegExp(r'^[\w\-.+]+@([\w-]+\.)+[\w-]{2,}$');
}
