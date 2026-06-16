part of project_screen;

extension _ProjectScreenHelpers on _ProjectScreenState {
  List<dynamic> _normalizeProjectResponse(dynamic decoded) {
    final rawProjects = decoded is List
        ? decoded
        : (decoded is Map<String, dynamic> && decoded['projects'] is List
            ? decoded['projects'] as List
            : const []);

    return rawProjects.map((p) {
      if (p is Map<String, dynamic> && p.containsKey('project')) {
        return p;
      }

      return {
        'project': p,
        'currentUserRole': null,
        'pendingInvitationUserIds': [],
        'stats': {
          'totalTasks': 0,
          'completedTasks': 0,
          'progressPercentage': 0,
        },
      };
    }).toList();
  }

  String _projectRole(dynamic projectData) {
    if (projectData is! Map<String, dynamic>) return 'Member';
    final project = projectData['project'];
    return (projectData['currentUserRole'] ??
            _roleForUser(project, _currentUserId()) ??
            'Member')
        .toString();
  }

  int _projectProgress(dynamic projectData) {
    if (projectData is! Map<String, dynamic>) return 0;
    final stats = projectData['stats'];
    final value = stats is Map ? stats['progressPercentage'] : 0;
    if (value is num) return value.round().clamp(0, 100);
    return int.tryParse(value?.toString() ?? '')?.clamp(0, 100) ?? 0;
  }

  String _projectStatus(dynamic projectData) {
    if (projectData is! Map<String, dynamic>) return 'Active';
    final project = projectData['project'];
    if (project is! Map) return 'Active';
    return (project['status'] ?? 'Active').toString();
  }

  Map<String, dynamic> _projectMap(dynamic projectData) {
    if (projectData is Map<String, dynamic> &&
        projectData['project'] is Map<String, dynamic>) {
      return projectData['project'] as Map<String, dynamic>;
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _projectStats(dynamic projectData) {
    if (projectData is Map<String, dynamic> &&
        projectData['stats'] is Map<String, dynamic>) {
      return projectData['stats'] as Map<String, dynamic>;
    }
    return <String, dynamic>{};
  }

  String _projectName(dynamic projectData) {
    final project = _projectMap(projectData);
    return (project['name'] ?? 'Untitled project').toString();
  }

  String _projectDescription(dynamic projectData) {
    final project = _projectMap(projectData);
    return (project['description'] ?? '').toString();
  }

  int _projectTotalTasks(dynamic projectData) {
    final value = _projectStats(projectData)['totalTasks'];
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _projectCompletedTasks(dynamic projectData) {
    final value = _projectStats(projectData)['completedTasks'];
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _projectOpenTasks(dynamic projectData) =>
      (_projectTotalTasks(projectData) - _projectCompletedTasks(projectData))
          .clamp(0, 9999);

  int _projectMemberCount(dynamic projectData) {
    final project = _projectMap(projectData);
    final members = project['members'] as List<dynamic>? ?? [];
    return members.length + (project['owner'] == null ? 0 : 1);
  }

  DateTime? _projectDueDate(dynamic projectData) {
    final project = _projectMap(projectData);
    final raw = project['deadline'] ?? project['dueDate'];
    return DateTime.tryParse(raw?.toString() ?? '');
  }

  int _stableProjectSeed(dynamic projectData) {
    final project = _projectMap(projectData);
    final source = (project['_id'] ?? project['name'] ?? '').toString();
    return source.codeUnits.fold<int>(0, (sum, code) => sum + code);
  }

  String _projectType(dynamic projectData) {
    final project = _projectMap(projectData);
    final explicit = project['type']?.toString();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    const types = ['Team', 'Work', 'Study', 'Personal'];
    return types[_stableProjectSeed(projectData) % types.length];
  }

  String _projectPriority(dynamic projectData) {
    final project = _projectMap(projectData);
    final explicit = project['priority']?.toString();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    if (_projectOpenTasks(projectData) >= 5 || _isProjectOverdue(projectData)) {
      return 'High';
    }
    if (_projectOpenTasks(projectData) >= 2) return 'Medium';
    return 'Normal';
  }

  bool _isProjectOverdue(dynamic projectData) {
    final due = _projectDueDate(projectData);
    if (due == null || _projectProgress(projectData) >= 100) return false;
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return due.isBefore(startOfToday);
  }

  bool _isProjectDueToday(dynamic projectData) {
    final due = _projectDueDate(projectData);
    if (due == null || _projectProgress(projectData) >= 100) return false;
    final now = DateTime.now();
    return due.year == now.year && due.month == now.month && due.day == now.day;
  }

  bool _isProjectDueSoon(dynamic projectData) {
    final due = _projectDueDate(projectData);
    if (due == null || _projectProgress(projectData) >= 100) return false;
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day).add(
      const Duration(days: 3),
    );
    return due.isAfter(now) && due.isBefore(end);
  }

  String _projectStateLabel(dynamic projectData) {
    final status = _projectStatus(projectData).trim().toLowerCase();
    if (status == 'completed') return 'Completed';
    if (status == 'on hold' || status == 'paused') return 'On Hold';
    return 'Active';
  }

  Color _projectStateColor(String label) {
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

  List<String> get _projectFilterOptions => const [
        'All',
        'Attention',
        'Active',
        'Completed',
      ];

  List<String> get _roleFilterOptions =>
      const ['All', 'Owner', 'Manager', 'Member'];

  List<String> get _typeFilterOptions =>
      const ['All', 'Personal', 'Team', 'Study', 'Work'];

  List<String> get _sortOptions =>
      const ['Recent', 'Deadline', 'Progress', 'Priority'];

  bool _projectNeedsAttention(dynamic projectData) {
    if (_projectProgress(projectData) >= 100) return false;
    final role = _projectRole(projectData);
    final manageable = role == 'Owner' || role == 'Manager';
    return _isProjectOverdue(projectData) ||
        _isProjectDueToday(projectData) ||
        _isProjectDueSoon(projectData) ||
        _projectPriority(projectData) == 'High' ||
        (manageable && _projectOpenTasks(projectData) > 0);
  }

  String _projectAttentionReason(dynamic projectData) {
    if (_isProjectOverdue(projectData)) return 'Overdue tasks';
    if (_isProjectDueToday(projectData)) return 'Due today';
    if (_isProjectDueSoon(projectData)) return 'Due soon';
    if (_projectPriority(projectData) == 'High') return 'High priority';
    if (_projectOpenTasks(projectData) > 0) return 'Tasks need action';
    return 'Needs review';
  }

  String _projectNextAction(dynamic projectData) {
    final openTasks = _projectOpenTasks(projectData);
    final progress = _projectProgress(projectData);
    final description = _projectDescription(projectData);
    if (openTasks == 0 && progress == 0) return 'Add first task';
    if (_isProjectOverdue(projectData)) return 'Resolve overdue work';
    if (_isProjectDueToday(projectData)) return 'Finish today tasks';
    if (progress >= 80 && progress < 100) return 'Review final tasks';
    if (openTasks > 0) return 'Complete next open task';
    if (description.isNotEmpty) return description;
    return 'Plan next milestone';
  }

  String _projectSubtitle(dynamic projectData) {
    final openTasks = _projectOpenTasks(projectData);
    if (openTasks == 0 && _projectTotalTasks(projectData) == 0) {
      return 'No tasks yet';
    }
    if (_projectNeedsAttention(projectData)) {
      return '$openTasks tasks need attention';
    }
    final description = _projectDescription(projectData);
    if (description.isNotEmpty) return description;
    return '$openTasks open tasks';
  }

  Color _projectAccentColor(dynamic projectData) {
    final label = _projectStateLabel(projectData);
    if (_isProjectOverdue(projectData)) {
      return Colors.redAccent;
    }
    if (label == 'Completed') {
      return Colors.green;
    }
    if (_isProjectDueSoon(projectData) || _isProjectDueToday(projectData)) {
      return const Color(0xFFF59E0B);
    }
    if (_projectType(projectData) == 'Personal') {
      return const Color(0xFF8B5CF6);
    }
    return _projectStateColor(label);
  }

  int _attentionScore(dynamic projectData) {
    var score = 0;
    if (_isProjectOverdue(projectData)) score += 60;
    if (_isProjectDueToday(projectData)) score += 45;
    if (_isProjectDueSoon(projectData)) score += 30;
    if (_projectPriority(projectData) == 'High') score += 20;
    score += _projectOpenTasks(projectData).clamp(0, 10);
    return score;
  }

  List<dynamic> get _visibleProjects {
    final query = _projectSearchQuery.trim().toLowerCase();
    final filtered = _projects.where((projectData) {
      final name = _projectName(projectData).toLowerCase();
      final description = _projectDescription(projectData).toLowerCase();
      if (query.isNotEmpty &&
          !name.contains(query) &&
          !description.contains(query)) {
        return false;
      }
      if (_roleFilter != 'All' && _projectRole(projectData) != _roleFilter) {
        return false;
      }
      if (_typeFilter != 'All' && _projectType(projectData) != _typeFilter) {
        return false;
      }
      if (_projectTab == 'Attention') {
        return _projectNeedsAttention(projectData);
      }
      if (_projectTab == 'Active') {
        return _projectStateLabel(projectData) == 'Active';
      }
      if (_projectTab == 'Completed') {
        return _projectStateLabel(projectData) == 'Completed';
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      if (_sortBy == 'Deadline') {
        final aDate = _projectDueDate(a);
        final bDate = _projectDueDate(b);
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      }
      if (_sortBy == 'Progress') {
        return _projectProgress(a).compareTo(_projectProgress(b));
      }
      if (_sortBy == 'Priority') {
        return _attentionScore(b).compareTo(_attentionScore(a));
      }
      final aCreated =
          DateTime.tryParse(_projectMap(a)['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
      final bCreated =
          DateTime.tryParse(_projectMap(b)['createdAt']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0);
      return bCreated.compareTo(aCreated);
    });

    return filtered;
  }

  List<dynamic> get _attentionProjects {
    final items = _projects
        .where((projectData) => _projectNeedsAttention(projectData))
        .toList();
    items.sort((a, b) => _attentionScore(b).compareTo(_attentionScore(a)));
    return items.take(5).toList();
  }

  int get _activeProjectCount => _projects.where((projectData) {
        return _projectStateLabel(projectData) == 'Active';
      }).length;

  String _projectDueText(dynamic projectData) {
    final due = _projectDueDate(projectData);
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

  ProjectCardModel _projectCardModel(dynamic projectData) {
    final status = _projectStateLabel(projectData);
    return ProjectCardModel(
      raw: projectData,
      name: _projectName(projectData),
      status: status,
      subtitle: _projectSubtitle(projectData),
      nextAction: _projectNextAction(projectData),
      progress: _projectProgress(projectData),
      completedTasks: _projectCompletedTasks(projectData),
      totalTasks: _projectTotalTasks(projectData),
      memberCount: _projectMemberCount(projectData),
      role: _projectRole(projectData),
      type: _projectType(projectData),
      dueText: _projectDueText(projectData),
      attentionReason: _projectAttentionReason(projectData),
      accentColor: _projectAccentColor(projectData),
      needsAttention: _projectNeedsAttention(projectData),
    );
  }

  void _clearProjectFilters() {
    _updateProjectState(() {
      _projectSearchController.clear();
      _projectSearchQuery = '';
      _projectTab = 'All';
      _roleFilter = 'All';
      _typeFilter = 'All';
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
              roleFilter: _roleFilter,
              typeFilter: _typeFilter,
              sortBy: _sortBy,
              roleOptions: _roleFilterOptions,
              typeOptions: _typeFilterOptions,
              sortOptions: _sortOptions,
              onRoleChanged: (value) {
                _updateProjectState(() => _roleFilter = value);
                modalSetState(() {});
              },
              onTypeChanged: (value) {
                _updateProjectState(() => _typeFilter = value);
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
    if (item is Map<String, dynamic>) {
      return (item['_id'] ?? item['id'] ?? '').toString();
    }
    return item?.toString() ?? '';
  }

  String? _extractUserId(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) {
      final id = _itemId(value);
      return id.isEmpty ? null : id;
    }
    final id = value.toString();
    return id.isEmpty ? null : id;
  }

  String? _userIdByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final user in _allUsers) {
      if (user is Map<String, dynamic> &&
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
    if (user is! Map<String, dynamic>) return '';
    final name = user['name']?.toString() ?? '';
    if (name.isNotEmpty) return name;
    final email = user['email']?.toString() ?? '';
    return email.contains('@') ? email.split('@')[0] : email;
  }

  String _assigneeDisplayName(dynamic assignee, Map<String, dynamic> project) {
    if (assignee is Map<String, dynamic>) {
      final name = _memberDisplayName(assignee);
      if (name.isNotEmpty) {
        return name;
      }
    }

    final assigneeId = _itemId(assignee);
    if (assigneeId.isEmpty) {
      return LocaleService.tr('Chua gan', en: 'Unassigned');
    }

    for (final user in _projectParticipants(project)) {
      if (_itemId(user) == assigneeId) {
        final name = _memberDisplayName(user);
        if (name.isNotEmpty) {
          return name;
        }
      }
    }

    return assigneeId;
  }

  List<dynamic> _projectParticipants(Map<String, dynamic> project) {
    final owner = project['owner'];
    final members = project['members'] as List<dynamic>? ?? [];
    return [if (owner != null) owner, ...members];
  }

  void _markInvited(Map<String, dynamic> projectData, String userId) {
    final pending =
        projectData['pendingInvitationUserIds'] as List<dynamic>? ?? [];
    if (!pending.map((id) => id.toString()).contains(userId)) {
      projectData['pendingInvitationUserIds'] = [...pending, userId];
    }
    final project = projectData['project'] as Map<String, dynamic>? ?? {};
    final projectId = project['_id']?.toString() ?? '';
    if (projectId.isNotEmpty) {
      _localPendingInviteIds
          .putIfAbsent(projectId, () => <String>{})
          .add(userId);
    }
  }

  String _roleForUser(Map<String, dynamic> project, String userId) {
    if (_itemId(project['owner']) == userId) return 'Owner';
    final roles = project['memberRoles'] as List<dynamic>? ?? [];
    for (final entry in roles) {
      if (entry is Map<String, dynamic> && _itemId(entry['user']) == userId) {
        return (entry['role'] ?? 'Member').toString();
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
