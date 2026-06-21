import 'package:flutter/material.dart';

import '../../../services/locale_service.dart';

/// Type of project supported by the backend. The backend persists these as
/// capitalised English strings ([apiValue]) — keep the enum and the API value
/// in sync if you add a new type.
enum ProjectType { personal, team, study, work }

/// UI / behavioural metadata for a [ProjectType]. Centralised here so the
/// type picker, project card, and any future surface reuse the same labels,
/// icons and colours instead of re-inventing them.
class ProjectTypeMeta {
  final ProjectType type;
  final String apiValue;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  /// `true` when the type expects collaborators (invitations + members
  /// settings are shown). `Personal` projects are single-user by default.
  final bool collaborative;

  const ProjectTypeMeta._({
    required this.type,
    required this.apiValue,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.collaborative,
  });

  static const ProjectTypeMeta personal = ProjectTypeMeta._(
    type: ProjectType.personal,
    apiValue: 'Personal',
    label: 'Personal',
    description: 'Just for you',
    icon: Icons.person_rounded,
    color: Color(0xFF8B5CF6),
    collaborative: false,
  );

  static const ProjectTypeMeta team = ProjectTypeMeta._(
    type: ProjectType.team,
    apiValue: 'Team',
    label: 'Team',
    description: 'Work with others',
    icon: Icons.groups_rounded,
    color: Color(0xFF06B6D4),
    collaborative: true,
  );

  static const ProjectTypeMeta study = ProjectTypeMeta._(
    type: ProjectType.study,
    apiValue: 'Study',
    label: 'Study',
    description: 'Coursework & learning',
    icon: Icons.school_rounded,
    color: Color(0xFF10B981),
    collaborative: true,
  );

  static const ProjectTypeMeta work = ProjectTypeMeta._(
    type: ProjectType.work,
    apiValue: 'Work',
    label: 'Work',
    description: 'Business projects',
    icon: Icons.work_rounded,
    color: Color(0xFFF59E0B),
    collaborative: true,
  );

  /// All metadata entries in the order they should appear in the picker.
  static const List<ProjectTypeMeta> all = [personal, team, study, work];

  static ProjectTypeMeta of(ProjectType type) {
    switch (type) {
      case ProjectType.personal:
        return personal;
      case ProjectType.team:
        return team;
      case ProjectType.study:
        return study;
      case ProjectType.work:
        return work;
    }
  }

  /// Localized version of [label]. Use this in UI; [label] stays English so
  /// it can serve as a stable identifier in tests and storage.
  String get localizedLabel {
    switch (type) {
      case ProjectType.personal:
        return LocaleService.tr('Cá nhân', en: 'Personal');
      case ProjectType.team:
        return LocaleService.tr('Nhóm', en: 'Team');
      case ProjectType.study:
        return LocaleService.tr('Học tập', en: 'Study');
      case ProjectType.work:
        return LocaleService.tr('Công việc', en: 'Work');
    }
  }

  /// Localized version of [description].
  String get localizedDescription {
    switch (type) {
      case ProjectType.personal:
        return LocaleService.tr('Riêng cho bạn', en: 'Just for you');
      case ProjectType.team:
        return LocaleService.tr('Làm cùng đồng đội', en: 'Work with others');
      case ProjectType.study:
        return LocaleService.tr('Học tập & môn học',
            en: 'Coursework & learning');
      case ProjectType.work:
        return LocaleService.tr('Dự án công việc', en: 'Business projects');
    }
  }
}
