part of project_screen;

extension _ProjectScreenHelpers on _ProjectScreenState {

  /// Primary tabs. "Mine" = projects this user owns or manages; "Shared" =
  /// projects this user is just a member of. "All" stays as the catch-all
  /// default. (Status — Active / On Hold / Completed — lives in the filter
  /// sheet instead so it doesn't double up with role here.)
  List<String> get _projectFilterOptions => const [
        'All',
        'Mine',
        'Shared',
      ];

  List<String> get _typeFilterOptions =>
      const ['All', 'Personal', 'Team', 'Study', 'Work'];

  List<String> get _statusFilterOptions =>
      const ['All', 'Active', 'On Hold', 'Completed'];

  List<String> get _sortOptions =>
      const ['Recent', 'Deadline', 'Progress', 'Priority'];

  List<ProjectModel> get _visibleProjects {
    final query = _projectSearchQuery.trim().toLowerCase();
    final filtered = _projects.where((projectData) {
      final name = projectData.name.toLowerCase();
      final description = projectData.description.toLowerCase();
      if (query.isNotEmpty &&
          !name.contains(query) &&
          !description.contains(query)) {
        return false;
      }
      if (_typeFilter != 'All' && projectData.type != _typeFilter) {
        return false;
      }
      if (_statusFilter != 'All' &&
          projectData.stateLabel != _statusFilter) {
        return false;
      }
      switch (_projectTab) {
        case 'Mine':
          if (projectData.role != 'Owner' &&
              projectData.role != 'Manager') {
            return false;
          }
          break;
        case 'Shared':
          if (projectData.role != 'Member') return false;
          break;
      }
      return true;
    }).toList();

    // Pin attention items to the top of the list when looking at "All", so
    // urgent projects rise above quieter ones without needing a separate
    // horizontal section.
    if (_projectTab == 'All' && _sortBy == 'Recent') {
      filtered.sort((a, b) {
        if (a.needsAttention != b.needsAttention) {
          return a.needsAttention ? -1 : 1;
        }
        if (a.needsAttention && b.needsAttention) {
          return b.attentionScore.compareTo(a.attentionScore);
        }
        final aCreated = a.project.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bCreated = b.project.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bCreated.compareTo(aCreated);
      });
      return filtered;
    }

    filtered.sort((a, b) {
      if (_sortBy == 'Deadline') {
        final aDate = a.deadline;
        final bDate = b.deadline;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      }
      if (_sortBy == 'Progress') {
        return a.progress.compareTo(b.progress);
      }
      if (_sortBy == 'Priority') {
        return b.attentionScore.compareTo(a.attentionScore);
      }
      final aCreated = a.project.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bCreated = b.project.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bCreated.compareTo(aCreated);
    });

    return filtered;
  }

  /// Build the grouped sections for the project list. Empty buckets are
  /// dropped so the UI doesn't render "0 projects" rows. Order is fixed
  /// per axis so users see the same layout each time. Returns an empty
  /// list when [_groupBy] is `'None'` — callers fall back to a flat list.
  List<ProjectGroupSection> get _groupedSections {
    if (_groupBy == 'None') return const [];
    final visible = _visibleProjects;

    if (_groupBy == 'Status') {
      const order = ['Active', 'On Hold', 'Completed'];
      const labelsVi = {
        'Active': 'Đang hoạt động',
        'On Hold': 'Tạm dừng',
        'Completed': 'Đã hoàn thành',
      };
      const icons = {
        'Active': Icons.play_circle_fill_rounded,
        'On Hold': Icons.pause_circle_filled_rounded,
        'Completed': Icons.check_circle_rounded,
      };
      const tints = {
        'Active': Color(0xFF06B6D4),
        'On Hold': Color(0xFFF59E0B),
        'Completed': Color(0xFF10B981),
      };
      final buckets = <String, List<ProjectModel>>{
        for (final s in order) s: <ProjectModel>[],
      };
      for (final p in visible) {
        buckets[p.stateLabel]?.add(p);
      }
      return [
        for (final key in order)
          if (buckets[key]!.isNotEmpty)
            ProjectGroupSection(
              key: key,
              label: LocaleService.tr(labelsVi[key]!, en: key),
              icon: icons[key]!,
              tint: tints[key]!,
              items: buckets[key]!,
            ),
      ];
    }

    // Default: group by Type
    const order = ['Personal', 'Team', 'Work', 'Study'];
    const labelsVi = {
      'Personal': 'Cá nhân',
      'Team': 'Nhóm',
      'Work': 'Công việc',
      'Study': 'Học tập',
    };
    const icons = {
      'Personal': Icons.person_rounded,
      'Team': Icons.groups_rounded,
      'Work': Icons.work_outline_rounded,
      'Study': Icons.school_outlined,
    };
    const tints = {
      'Personal': Color(0xFF8B5CF6),
      'Team': Color(0xFF06B6D4),
      'Work': Color(0xFF0EA5E9),
      'Study': Color(0xFFEC4899),
    };
    final buckets = <String, List<ProjectModel>>{
      for (final t in order) t: <ProjectModel>[],
    };
    for (final p in visible) {
      buckets[p.type]?.add(p);
    }
    return [
      for (final key in order)
        if (buckets[key]!.isNotEmpty)
          ProjectGroupSection(
            key: key,
            label: LocaleService.tr(labelsVi[key]!, en: key),
            icon: icons[key]!,
            tint: tints[key]!,
            items: buckets[key]!,
          ),
    ];
  }

  List<ProjectModel> get _attentionProjects {
    final items = _projects
        .where((projectData) => projectData.needsAttention)
        .toList();
    items.sort((a, b) => b.attentionScore.compareTo(a.attentionScore));
    return items.take(5).toList();
  }

  int get _activeProjectCount => _projects.where((projectData) {
        return projectData.stateLabel == 'Active';
      }).length;

  void _clearProjectFilters() {
    _updateProjectState(() {
      _projectSearchController.clear();
      _projectSearchQuery = '';
      _projectTab = 'All';
      _typeFilter = 'All';
      _statusFilter = 'All';
      _sortBy = 'Recent';
    });
  }

  void _showProjectFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, modalSetState) {
            return ProjectFilterBottomSheet(
              typeFilter: _typeFilter,
              statusFilter: _statusFilter,
              sortBy: _sortBy,
              typeOptions: _typeFilterOptions,
              statusOptions: _statusFilterOptions,
              sortOptions: _sortOptions,
              onTypeChanged: (value) {
                _updateProjectState(() => _typeFilter = value);
                modalSetState(() {});
              },
              onStatusChanged: (value) {
                _updateProjectState(() => _statusFilter = value);
                modalSetState(() {});
              },
              onSortChanged: (value) {
                _updateProjectState(() => _sortBy = value);
                modalSetState(() {});
              },
              onClear: () {
                _clearProjectFilters();
                modalSetState(() {});
              },
            );
          },
        );
      },
    );
  }

  String _itemId(dynamic item) {
    if (item is ProjectMember) return item.id;
    if (item is Map) {
      return (item['_id'] ?? item['id'] ?? '').toString();
    }
    return item?.toString() ?? '';
  }

  String? _extractUserId(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      final id = _itemId(value);
      return id.isEmpty ? null : id;
    }
    final id = value.toString();
    return id.isEmpty ? null : id;
  }

  String? _userIdByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final user in _allUsers) {
      if (user is Map &&
          (user['email'] ?? '').toString().toLowerCase() == normalized) {
        final id = _itemId(user);
        return id.isEmpty ? null : id;
      }
    }
    return null;
  }

  String _currentUserId() =>
      (_currentUser?['_id'] ?? _currentUser?['id'] ?? '').toString();

  String _memberDisplayName(dynamic user) {
    if (user is ProjectMember) {
      final nameClean = user.name.trim();
      final hasRealName = nameClean.isNotEmpty && nameClean.toLowerCase() != 'member';
      return hasRealName
          ? nameClean
          : (user.email.contains('@') ? user.email.split('@')[0] : user.email);
    }
    if (user is! Map) return '';
    final nameClean = (user['name']?.toString() ?? '').trim();
    final hasRealName = nameClean.isNotEmpty && nameClean.toLowerCase() != 'member';
    if (hasRealName) return nameClean;
    final email = (user['email']?.toString() ?? '').trim();
    return email.contains('@') ? email.split('@')[0] : email;
  }

  String _assigneeDisplayName(dynamic assignee, ProjectDetails project) {
    if (assignee is Map) {
      final nameClean = (assignee['name']?.toString() ?? '').trim();
      final hasRealName = nameClean.isNotEmpty && nameClean.toLowerCase() != 'member';
      if (hasRealName) {
        return nameClean;
      }
      final email = (assignee['email']?.toString() ?? '').trim();
      if (email.isNotEmpty) {
        return email.contains('@') ? email.split('@')[0] : email;
      }
    }

    final assigneeId = _itemId(assignee);
    if (assigneeId.isEmpty) {
      return LocaleService.tr('Chua gan', en: 'Unassigned');
    }

    for (final user in _projectParticipants(project)) {
      if (user.id == assigneeId) {
        final displayName = _memberDisplayName(user);
        if (displayName.isNotEmpty) {
          return displayName;
        }
      }
    }

    return assigneeId;
  }

  List<ProjectMember> _projectParticipants(ProjectDetails project) {
    final owner = project.owner;
    final members = project.members;
    return [if (owner != null) owner, ...members];
  }

  void _markInvited(ProjectModel projectData, String userId) {
    final projectId = projectData.project.id;
    if (projectId.isNotEmpty) {
      _localPendingInviteIds
          .putIfAbsent(projectId, () => <String>{})
          .add(userId);
    }
  }

  String _roleForUser(ProjectDetails project, String userId) {
    if (project.owner?.id == userId) return 'Owner';
    for (final entry in project.memberRoles) {
      if (entry.userId == userId) {
        return entry.role;
      }
    }
    return 'Member';
  }

  void _resetTaskScheduleFields() {
    _taskDueDate = null;
    _taskDueTime = null;
    _taskReminderType = 'none';
    _taskReminderOffset = null;
    _taskNotificationEnabled = false;
  }

  TimeOfDay? _parseTaskTime(dynamic value) {
    final raw = value?.toString() ?? '';
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime? _parseTaskDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  void _setTaskScheduleFromTask(Map<String, dynamic> task) {
    _taskDueDate = _parseTaskDate(task['dueDate'] ?? task['deadline']);
    _taskDueTime = _parseTaskTime(task['dueTime']);
    _taskReminderType = (task['reminderType'] ?? 'none').toString();
    _taskReminderOffset = task['reminderOffset'] is num
        ? (task['reminderOffset'] as num).round()
        : int.tryParse(task['reminderOffset']?.toString() ?? '');
    _taskNotificationEnabled =
        task['notificationEnabled'] == true && _taskReminderType != 'none';
  }

  DateTime _combinedTaskDueDateTime() {
    final date = _taskDueDate ?? DateTime.now();
    final time = _taskDueTime ?? const TimeOfDay(hour: 23, minute: 59);
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  String _timeToApiString(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Pick date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _timeLabel(TimeOfDay? time) {
    if (time == null) return 'End of day';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _taskReminderLabelFromType(String type) {
    switch (type) {
      case 'at_time':
        return 'At due time';
      case '15_min_before':
        return '15 min before';
      case '30_min_before':
        return '30 min before';
      case '1_hour_before':
        return '1 hour before';
      case '1_day_before':
        return '1 day before';
      case 'custom':
        return 'Custom';
      default:
        return 'No reminder';
    }
  }

  // ignore: unused_element
  String _taskDueLabel(Map<String, dynamic> task) {
    final due = _parseTaskDate(task['dueDate'] ?? task['deadline']);
    if (due == null) return 'No due date';
    final time = _parseTaskTime(task['dueTime']);
    return '${_dateLabel(due)} · ${_timeLabel(time)}';
  }

  // ignore: unused_element
  bool _taskIsOverdue(Map<String, dynamic> task) {
    final status = (task['status'] ?? '').toString();
    if (status == 'Completed') return false;
    final due = _parseTaskDate(task['dueDate'] ?? task['deadline']);
    if (due == null) return false;
    final time = _parseTaskTime(task['dueTime']);
    final dueAt = DateTime(
      due.year,
      due.month,
      due.day,
      time?.hour ?? 23,
      time?.minute ?? 59,
    );
    return dueAt.isBefore(DateTime.now());
  }

  Map<String, dynamic> _taskSchedulePayload() {
    final dueAt = _combinedTaskDueDateTime();
    return {
      'deadline': dueAt.toIso8601String(),
      'dueDate': dueAt.toIso8601String(),
      'dueTime': _timeToApiString(_taskDueTime),
      'reminderType': _taskReminderType,
      'reminderOffset':
          _taskReminderType == 'custom' ? (_taskReminderOffset ?? 0) : null,
      'notificationEnabled':
          _taskNotificationEnabled && _taskReminderType != 'none',
    };
  }

  bool _canManage(String? role) => role == 'Owner' || role == 'Manager';

  // ignore: unused_element
  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
