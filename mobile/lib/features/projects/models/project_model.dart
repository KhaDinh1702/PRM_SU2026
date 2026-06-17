import 'package:flutter/material.dart';

class ProjectMember {
  final String id;
  final String name;
  final String email;

  const ProjectMember({
    required this.id,
    required this.name,
    required this.email,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
    };
  }
}

class ProjectMemberRole {
  final String userId;
  final String role;

  const ProjectMemberRole({
    required this.userId,
    required this.role,
  });

  factory ProjectMemberRole.fromJson(Map<String, dynamic> json) {
    final userVal = json['user'];
    final userId = userVal is Map
        ? (userVal['_id'] ?? userVal['id'] ?? '').toString()
        : userVal?.toString() ?? '';
    return ProjectMemberRole(
      userId: userId,
      role: (json['role'] ?? 'Member').toString(),
    );
  }
}

class ProjectDetails {
  final String id;
  final String name;
  final String description;
  final ProjectMember? owner;
  final List<ProjectMember> members;
  final List<ProjectMemberRole> memberRoles;
  final DateTime? deadline;
  final String status;
  final String type;
  final bool allowMembersToCreateTasks;
  final DateTime? createdAt;

  const ProjectDetails({
    required this.id,
    required this.name,
    required this.description,
    this.owner,
    required this.members,
    required this.memberRoles,
    this.deadline,
    required this.status,
    required this.type,
    required this.allowMembersToCreateTasks,
    this.createdAt,
  });

  factory ProjectDetails.fromJson(Map<String, dynamic> json) {
    final rawOwner = json['owner'];
    ProjectMember? owner;
    if (rawOwner != null) {
      if (rawOwner is Map) {
        owner = ProjectMember.fromJson(Map<String, dynamic>.from(rawOwner));
      } else {
        owner = ProjectMember(id: rawOwner.toString(), name: '', email: '');
      }
    }

    final rawMembers = json['members'] as List<dynamic>? ?? [];
    final members = rawMembers.map((m) {
      if (m is Map) {
        return ProjectMember.fromJson(Map<String, dynamic>.from(m));
      }
      return ProjectMember(id: m.toString(), name: '', email: '');
    }).toList();

    final rawRoles = json['memberRoles'] as List<dynamic>? ?? [];
    final roles = rawRoles.map((r) {
      if (r is Map) {
        return ProjectMemberRole.fromJson(Map<String, dynamic>.from(r));
      }
      return ProjectMemberRole(userId: '', role: 'Member');
    }).toList();

    final deadlineStr = json['deadline'] ?? json['dueDate'];

    return ProjectDetails(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Untitled project').toString(),
      description: (json['description'] ?? '').toString(),
      owner: owner,
      members: members,
      memberRoles: roles,
      deadline: deadlineStr != null ? DateTime.tryParse(deadlineStr.toString())?.toLocal() : null,
      status: (json['status'] ?? 'Active').toString(),
      type: (json['type'] ?? '').toString(),
      allowMembersToCreateTasks: json['allowMembersToCreateTasks'] == true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString())?.toLocal() : null,
    );
  }
}

class ProjectStats {
  final int totalTasks;
  final int completedTasks;
  final int progressPercentage;

  const ProjectStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.progressPercentage,
  });

  factory ProjectStats.fromJson(Map<String, dynamic> json) {
    final total = json['totalTasks'];
    final completed = json['completedTasks'];
    final progress = json['progressPercentage'];

    int parseNum(dynamic val) {
      if (val is num) return val.round();
      return int.tryParse(val?.toString() ?? '') ?? 0;
    }

    return ProjectStats(
      totalTasks: parseNum(total),
      completedTasks: parseNum(completed),
      progressPercentage: parseNum(progress).clamp(0, 100),
    );
  }

  factory ProjectStats.empty() {
    return const ProjectStats(totalTasks: 0, completedTasks: 0, progressPercentage: 0);
  }
}

class ProjectModel {
  final ProjectDetails project;
  final String? currentUserRole;
  final List<String> pendingInvitationUserIds;
  final ProjectStats stats;

  const ProjectModel({
    required this.project,
    this.currentUserRole,
    required this.pendingInvitationUserIds,
    required this.stats,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('project')) {
      final projVal = json['project'];
      final statsVal = json['stats'];
      final rawPending = json['pendingInvitationUserIds'] as List<dynamic>? ?? [];
      final pending = rawPending.map((id) => id.toString()).toList();

      return ProjectModel(
        project: ProjectDetails.fromJson(projVal is Map ? Map<String, dynamic>.from(projVal) : const {}),
        currentUserRole: json['currentUserRole']?.toString(),
        pendingInvitationUserIds: pending,
        stats: ProjectStats.fromJson(statsVal is Map ? Map<String, dynamic>.from(statsVal) : const {}),
      );
    } else {
      final proj = ProjectDetails.fromJson(json);
      return ProjectModel(
        project: proj,
        currentUserRole: null,
        pendingInvitationUserIds: const [],
        stats: ProjectStats.empty(),
      );
    }
  }

  String get role => currentUserRole ?? _roleForUser(project.owner?.id ?? '');

  String _roleForUser(String ownerId) {
    if (project.owner?.id == ownerId) return 'Owner';
    for (final entry in project.memberRoles) {
      if (entry.userId == ownerId) return entry.role;
    }
    return 'Member';
  }

  int get progress => stats.progressPercentage;

  String get status => project.status;

  String get name => project.name;

  String get description => project.description;

  int get totalTasks => stats.totalTasks;

  int get completedTasks => stats.completedTasks;

  int get openTasks => (totalTasks - completedTasks).clamp(0, 9999);

  int get memberCount => project.members.length + (project.owner == null ? 0 : 1);

  DateTime? get deadline => project.deadline;

  int get stableSeed {
    final source = (project.id.isNotEmpty ? project.id : project.name);
    return source.codeUnits.fold<int>(0, (sum, code) => sum + code);
  }

  String get type {
    if (project.type.isNotEmpty) return project.type;
    const types = ['Team', 'Work', 'Study', 'Personal'];
    return types[stableSeed % types.length];
  }

  String get priority {
    if (openTasks >= 5 || isOverdue) return 'High';
    if (openTasks >= 2) return 'Medium';
    return 'Normal';
  }

  bool get isOverdue {
    final due = deadline;
    if (due == null || progress >= 100) return false;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return due.isBefore(startOfToday);
  }

  bool get isDueToday {
    final due = deadline;
    if (due == null || progress >= 100) return false;
    final now = DateTime.now();
    return due.year == now.year && due.month == now.month && due.day == now.day;
  }

  bool get isDueSoon {
    final due = deadline;
    if (due == null || progress >= 100) return false;
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day).add(const Duration(days: 3));
    return due.isAfter(now) && due.isBefore(end);
  }

  String get stateLabel {
    final s = status.trim().toLowerCase();
    if (s == 'completed') return 'Completed';
    if (s == 'on hold' || s == 'paused') return 'On Hold';
    return 'Active';
  }

  bool get needsAttention {
    if (progress >= 100) return false;
    final userRole = role;
    final manageable = userRole == 'Owner' || userRole == 'Manager';
    return isOverdue || isDueToday || isDueSoon || priority == 'High' || (manageable && openTasks > 0);
  }

  String get attentionReason {
    if (isOverdue) return 'Overdue tasks';
    if (isDueToday) return 'Due today';
    if (isDueSoon) return 'Due soon';
    if (priority == 'High') return 'High priority';
    if (openTasks > 0) return 'Tasks need action';
    return 'Needs review';
  }

  String get nextAction {
    if (openTasks == 0 && progress == 0) return 'Add first task';
    if (isOverdue) return 'Resolve overdue work';
    if (isDueToday) return 'Finish today tasks';
    if (progress >= 80 && progress < 100) return 'Review final tasks';
    if (openTasks > 0) return 'Complete next open task';
    if (description.isNotEmpty) return description;
    return 'Plan next milestone';
  }

  String get subtitle {
    if (openTasks == 0 && totalTasks == 0) return 'No tasks yet';
    if (needsAttention) return '$openTasks tasks need attention';
    if (description.isNotEmpty) return description;
    return '$openTasks open tasks';
  }

  String get dueText {
    final due = deadline;
    if (due == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(due.year, due.month, due.day);
    final days = dueDay.difference(today).inDays;
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days < 0) return '${days.abs()}d overdue';
    return 'Due in ${days}d';
  }

  Color get accentColor {
    final label = stateLabel;
    if (isOverdue) return Colors.redAccent;
    if (label == 'Completed') return Colors.green;
    if (isDueSoon || isDueToday) return const Color(0xFFF59E0B);
    if (type == 'Personal') return const Color(0xFF8B5CF6);

    switch (label) {
      case 'Completed':
        return Colors.green;
      case 'On Hold':
        return Colors.orange;
      case 'Due soon':
        return const Color(0xFFF59E0B);
      case 'Active':
        return const Color(0xFF06B6D4);
      case 'Personal':
        return const Color(0xFF8B5CF6);
      default:
        return Colors.blueGrey;
    }
  }

  int get attentionScore {
    var score = 0;
    if (isOverdue) score += 60;
    if (isDueToday) score += 45;
    if (isDueSoon) score += 30;
    if (priority == 'High') score += 20;
    score += openTasks.clamp(0, 10);
    return score;
  }
}
