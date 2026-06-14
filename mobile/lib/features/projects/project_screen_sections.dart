part of project_screen;

extension _ProjectScreenSections on _ProjectScreenState {
  Future<void> _pickTaskDueDate(
    BuildContext context,
    StateSetter setDialogState,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _taskDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setDialogState(() => _taskDueDate = picked);
    }
  }

  Future<void> _pickTaskDueTime(
    BuildContext context,
    StateSetter setDialogState,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _taskDueTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) {
      if (_isDueTimeInPast(_taskDueDate ?? DateTime.now(), picked)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Due time cannot be in the past.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      setDialogState(() => _taskDueTime = picked);
    }
  }

  Widget _buildQuickOptionTile({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    bool disabled = false,
  }) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF06B6D4).withOpacity(0.14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? const Color(0xFF06B6D4)
                : ThemeService.getBorderColor(ThemeService.isDarkMode.value),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: disabled
                    ? Colors.grey
                    : selected
                        ? const Color(0xFF06B6D4)
                        : null,
              ),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: disabled
                      ? Colors.grey
                      : selected
                          ? const Color(0xFF06B6D4)
                          : null,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoColumnOptions({required List<Widget> children}) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: children[i]),
            const SizedBox(width: 10),
            Expanded(
              child: i + 1 < children.length
                  ? children[i + 1]
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
      if (i + 2 < children.length) rows.add(const SizedBox(height: 10));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _buildRoundedDropdown<T>({
    required T? value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required Color dialogBg,
    required Color textColor,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: dialogBg,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: ThemeService.getBorderColor(ThemeService.isDarkMode.value),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: ThemeService.getBorderColor(ThemeService.isDarkMode.value),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF06B6D4), width: 1.4),
        ),
      ),
      style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
      items: items,
      onChanged: onChanged,
    );
  }

  bool _isDueTimeInPast(DateTime date, TimeOfDay time) {
    final now = DateTime.now();
    final dueAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return dueAt.isBefore(now);
  }

  Widget _buildTaskScheduleFields({
    required BuildContext context,
    required StateSetter setDialogState,
    required Color textColor,
    required Color captionColor,
    required Color dialogBg,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _pickTaskDueDate(context, setDialogState),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: ThemeService.isDarkMode.value
                        ? Colors.white.withOpacity(0.03)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ThemeService.getBorderColor(
                          ThemeService.isDarkMode.value),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          color: Color(0xFF06B6D4), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Due date *',
                              style: TextStyle(
                                  color: captionColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _taskDueDate == null
                                  ? 'Select Date'
                                  : _dateLabel(_taskDueDate),
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: () => _pickTaskDueTime(context, setDialogState),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: ThemeService.isDarkMode.value
                        ? Colors.white.withOpacity(0.03)
                        : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ThemeService.getBorderColor(
                          ThemeService.isDarkMode.value),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          color: Color(0xFF06B6D4), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Due time *',
                              style: TextStyle(
                                  color: captionColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _taskDueTime == null
                                  ? 'Select Time'
                                  : _timeLabel(_taskDueTime),
                              style: TextStyle(
                                  color: textColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildRoundedDropdown<String>(
          value: _taskReminderType,
          label: 'Reminder',
          dialogBg: dialogBg,
          textColor: textColor,
          items: const [
            'none',
            'at_time',
            '15_min_before',
            '30_min_before',
            '1_hour_before',
            '1_day_before',
          ].map((value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                _taskReminderLabelFromType(value),
                style: TextStyle(color: textColor),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setDialogState(() {
                _taskReminderType = value;
                _taskNotificationEnabled = value != 'none';
              });
            }
          },
        ),
        const SizedBox(height: 12),
        _buildRoundedDropdown<String>(
          value: _taskPriority,
          label: 'Priority',
          dialogBg: dialogBg,
          textColor: textColor,
          items: ['Low', 'Medium', 'High', 'Urgent']
              .map(
                (priority) => DropdownMenuItem(
                  value: priority,
                  child: Text(priority, style: TextStyle(color: textColor)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setDialogState(() => _taskPriority = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildAssigneeDropdown({
    required List<dynamic> participants,
    required StateSetter setDialogState,
    required Color dialogBg,
    required Color textColor,
  }) {
    final items = participants.map((user) {
      final id = _itemId(user);
      return DropdownMenuItem<String>(
        value: id,
        child: Text(
          _memberDisplayName(user),
          style: TextStyle(color: textColor),
        ),
      );
    }).toList();
    final selectedValue = items.any((item) => item.value == _selectedAssigneeId)
        ? _selectedAssigneeId
        : null;

    return _buildRoundedDropdown<String>(
      value: selectedValue,
      label: LocaleService.tr('Nguoi nhan task', en: 'Assignee'),
      dialogBg: dialogBg,
      textColor: textColor,
      items: items,
      onChanged: items.isEmpty
          ? (_) {}
          : (value) => setDialogState(() => _selectedAssigneeId = value),
    );
  }

  void _showCreateProjectTaskDialog(
      Map<String, dynamic> project, StateSetter sheetSetState) {
    final participants = _projectParticipants(project);
    _selectedAssigneeId = participants.isNotEmpty
        ? _itemId(participants.first)
        : _currentUserId();
    _taskTitleController.clear();
    _taskDescController.clear();
    _taskPriority = 'Medium';
    _resetTaskScheduleFields();
    _taskDueDate = DateTime.now();
    _taskDueTime = const TimeOfDay(hour: 18, minute: 0);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = ThemeService.isDarkMode.value;
            final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
            final textColor = ThemeService.getTextColor(isDark);
            final captionColor = ThemeService.getCaptionColor(isDark);

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: AlertDialog(
                backgroundColor: dialogBg.withOpacity(0.94),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text(
                  LocaleService.tr('PHAN TASK', en: 'ASSIGN TASK'),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PremiumInputField(
                        controller: _taskTitleController,
                        label:
                            LocaleService.tr('Ten task *', en: 'Task title *'),
                        hintText: LocaleService.tr('Nhap ten task...',
                            en: 'Enter task...'),
                        prefixIcon: Icons.task_alt_rounded,
                      ),
                      const SizedBox(height: 12),
                      PremiumInputField(
                        controller: _taskDescController,
                        label: LocaleService.tr('Mo ta', en: 'Description'),
                        hintText: LocaleService.tr('Nhap mo ta...',
                            en: 'Enter details...'),
                        prefixIcon: Icons.description_outlined,
                      ),
                      const SizedBox(height: 14),
                      _buildAssigneeDropdown(
                        participants: participants,
                        setDialogState: setDialogState,
                        dialogBg: dialogBg,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 12),
                      _buildTaskScheduleFields(
                        context: context,
                        setDialogState: setDialogState,
                        textColor: textColor,
                        captionColor: captionColor,
                        dialogBg: dialogBg,
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(LocaleService.tr('Huy', en: 'Cancel'),
                        style: TextStyle(color: captionColor)),
                  ),
                  PremiumButton(
                    onPressed: _isSavingProjectTask
                        ? null
                        : () => _createProjectTask(
                            project['_id'], sheetSetState, setDialogState),
                    backgroundColor: const Color(0xFF06B6D4),
                    child: _isSavingProjectTask
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Assign',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProjectOverviewTab(
    Map<String, dynamic> projectData,
    Map<String, dynamic> project,
    Map<String, dynamic> stats,
    Color textColor,
    Color subTextColor,
    Color captionColor,
    bool isDark,
    StateSetter sheetSetState,
  ) {
    final total = _projectTotalTasks(projectData);
    final completed = _projectCompletedTasks(projectData);
    final progress = _projectProgress(projectData);
    final memberCount = _projectMemberCount(projectData);
    final role = _projectRole(projectData);
    final workStatus = _projectStateLabel(projectData);
    final statusColor = _projectAccentColor(projectData);
    final openTasks = _projectOpenTasks(projectData);

    String title;
    String text;
    String cta;
    VoidCallback action;

    if (_isProjectOverdue(projectData)) {
      title = 'Needs attention';
      text = '$openTasks open tasks need review. Start with overdue work.';
      cta = 'Review overdue tasks';
      action = () => DefaultTabController.of(context).animateTo(1);
    } else if (total == 0) {
      title = 'Get started';
      text =
          'No tasks have been created yet. Create the first task to start tracking progress.';
      cta = 'Add first task';
      action = () => _showCreateProjectTaskDialog(project, sheetSetState);
    } else {
      final nextTask = _projectTasks.isNotEmpty
          ? _projectTasks.firstWhere(
              (task) => (task['status'] ?? '') != 'Completed',
              orElse: () => _projectTasks.first,
            )
          : null;
      title = 'Next up';
      text = nextTask == null
          ? '$openTasks open tasks remaining.'
          : '${nextTask['title'] ?? 'Next task'} · ${_assigneeDisplayName(nextTask['assignedTo'] ?? nextTask['user'], project)}';
      cta = 'View task';
      action = () => DefaultTabController.of(context).animateTo(1);
    }

    return OverviewTab(
      description: _projectDescription(projectData),
      actionTitle: title,
      actionText: text,
      actionLabel: cta,
      actionColor: statusColor,
      onAction: action,
      progress: progress,
      completedTasks: completed,
      totalTasks: total,
      memberCount: memberCount,
      role: role,
      workStatus: workStatus,
      workStatusColor: statusColor,
    );
  }

  Widget _buildOverviewMetric(
      String label, String value, IconData icon, Color color) {
    final isDark = ThemeService.isDarkMode.value;
    final textColor = ThemeService.getTextColor(isDark);
    final captionColor = ThemeService.getCaptionColor(isDark);

    return GlassCard(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: captionColor, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildProjectTasksTab(
    Map<String, dynamic> project,
    bool canManage,
    Color textColor,
    Color subTextColor,
    Color captionColor,
    StateSetter sheetSetState,
  ) {
    return TasksTab(
      tasks: _projectTasks,
      selectedFilter: _taskFilter,
      isLoading: _isLoadingProjectTasks,
      tasksLoaded: _projectTasksLoaded,
      canManage: canManage,
      onFilterChanged: (filter) {
        _updateProjectState(() => _taskFilter = filter);
        sheetSetState(() {});
      },
      onAddTask: () => _showCreateProjectTaskDialog(project, sheetSetState),
      onLoadTasks: () => _loadProjectTasks(project['_id'], sheetSetState),
      assigneeName: (assignee) => _assigneeDisplayName(assignee, project),
      canUpdateTask: (task) {
        final assignee = task['assignedTo'] ?? task['user'];
        return canManage || _itemId(assignee) == _currentUserId();
      },
      onEditTask: (task) =>
          _showEditProjectTaskDialog(project, task, sheetSetState),
      onUpdateStatus: (task, status) => _updateProjectTaskStatus(
        project['_id'],
        task['_id'],
        status,
        sheetSetState,
      ),
    );
  }

  Widget _buildProjectMembersTab(
    Map<String, dynamic> projectData,
    bool isOwner,
    bool canManage,
    Color textColor,
    Color captionColor,
    StateSetter sheetSetState,
  ) {
    final project = projectData['project'] as Map<String, dynamic>;
    final participants = _projectParticipants(project);
    final owners = participants
        .where((user) => _roleForUser(project, _itemId(user)) == 'Owner')
        .toList();
    final managers = participants
        .where((user) => _roleForUser(project, _itemId(user)) == 'Manager')
        .toList();
    final regularMembers = participants
        .where((user) => _roleForUser(project, _itemId(user)) == 'Member')
        .toList();

    return MembersTab(
      owners: owners,
      managers: managers,
      members: regularMembers,
      canInvite: canManage,
      canEditRoles: isOwner,
      onRoleChanged: (user, role) async {
        final userId = _itemId(user);
        if (userId.isEmpty) return;
        await _updateMemberRole(
          project['_id'].toString(),
          userId,
          role,
          projectData,
          sheetSetState,
        );
        sheetSetState(() {});
      },
      onInvite: () async {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Invite member'),
            content: PremiumInputField(
              controller: _memberEmailController,
              label: 'Email',
              hintText: 'Enter email...',
              prefixIcon: Icons.mail_outline_rounded,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final invitedUserId = await _addMember(project['_id']);
                  if (invitedUserId != null) {
                    _markInvited(projectData, invitedUserId);
                  }
                  sheetSetState(() {});
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Invite'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProjectChatTab(
    Map<String, dynamic> project,
    Color textColor,
    Color subTextColor,
  ) {
    return ChatTab(
      onOpenChat: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ChatBottomSheet(
            projectId: project['_id'],
            projectName: project['name'] ?? 'Project',
          ),
        );
      },
    );
  }

  void _showEditProjectTaskDialog(Map<String, dynamic> project,
      Map<String, dynamic> task, StateSetter sheetSetState) {
    final participants = _projectParticipants(project);
    final currentAssigneeId = _itemId(task['assignedTo'] ?? task['user']);
    _taskTitleController.text = (task['title'] ?? '').toString();
    _taskDescController.text = (task['description'] ?? '').toString();
    _taskPriority = (task['priority'] ?? 'Medium').toString();
    _setTaskScheduleFromTask(task);
    _taskDueDate ??= DateTime.now();
    _selectedAssigneeId =
        participants.any((user) => _itemId(user) == currentAssigneeId)
            ? currentAssigneeId
            : (participants.isNotEmpty
                ? _itemId(participants.first)
                : _currentUserId());
    String taskStatus = (task['status'] ?? 'Pending').toString();
    bool isSaving = false;
    String? editError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = ThemeService.isDarkMode.value;
            final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
            final textColor = ThemeService.getTextColor(isDark);
            final captionColor = ThemeService.getCaptionColor(isDark);

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: AlertDialog(
                backgroundColor: dialogBg.withOpacity(0.94),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text(
                  LocaleService.tr('SUA TASK', en: 'EDIT TASK'),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PremiumInputField(
                        controller: _taskTitleController,
                        label:
                            LocaleService.tr('Ten task *', en: 'Task title *'),
                        hintText: LocaleService.tr('Nhap ten task...',
                            en: 'Enter task...'),
                        prefixIcon: Icons.task_alt_rounded,
                      ),
                      const SizedBox(height: 12),
                      PremiumInputField(
                        controller: _taskDescController,
                        label: LocaleService.tr('Mo ta', en: 'Description'),
                        hintText: LocaleService.tr('Nhap mo ta...',
                            en: 'Enter details...'),
                        prefixIcon: Icons.description_outlined,
                      ),
                      const SizedBox(height: 14),
                      _buildAssigneeDropdown(
                        participants: participants,
                        setDialogState: setDialogState,
                        dialogBg: dialogBg,
                        textColor: textColor,
                      ),
                      const SizedBox(height: 12),
                      _buildTaskScheduleFields(
                        context: context,
                        setDialogState: setDialogState,
                        textColor: textColor,
                        captionColor: captionColor,
                        dialogBg: dialogBg,
                      ),
                      const SizedBox(height: 12),
                      _buildRoundedDropdown<String>(
                        value: taskStatus,
                        label: 'Status',
                        dialogBg: dialogBg,
                        textColor: textColor,
                        items: ['Pending', 'In Progress', 'Completed']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status,
                                      style: TextStyle(color: textColor)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => taskStatus = value);
                          }
                        },
                      ),
                      if (editError != null) ...[
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            editError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    child: Text(LocaleService.tr('Huy', en: 'Cancel'),
                        style: TextStyle(color: captionColor)),
                  ),
                  PremiumButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final title = _taskTitleController.text.trim();
                            if (title.isEmpty ||
                                _selectedAssigneeId == null ||
                                _taskDueDate == null) {
                              setDialogState(() {
                                editError = LocaleService.tr(
                                    'Vui lÃ²ng nháº­p Ä‘áº§y Ä‘á»§ thÃ´ng tin.',
                                    en: 'Task title, assignee, and due date are required.');
                              });
                              return;
                            }
                            if (_combinedTaskDueDateTime()
                                .isBefore(DateTime.now())) {
                              setDialogState(() {
                                editError =
                                    'Due date and time cannot be in the past.';
                              });
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                              editError = null;
                            });

                            final error = await _updateProjectTask(
                              project['_id'],
                              task['_id'],
                              {
                                'title': title,
                                'description': _taskDescController.text.trim(),
                                'priority': _taskPriority,
                                'assignedTo': _selectedAssigneeId,
                                'status': taskStatus,
                                ..._taskSchedulePayload(),
                              },
                              sheetSetState,
                            );
                            if (error != null && mounted) {
                              setDialogState(() {
                                isSaving = false;
                                editError = error;
                              });
                            }
                          },
                    backgroundColor: const Color(0xFF06B6D4),
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditProjectDialog(
    Map<String, dynamic> projectData,
    StateSetter sheetSetState,
  ) {
    final project = projectData['project'] as Map<String, dynamic>;
    _nameController.text = (project['name'] ?? '').toString();
    _descController.text = (project['description'] ?? '').toString();
    String status = (project['status'] ?? 'Active').toString();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isDark = ThemeService.isDarkMode.value;
            final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
            final textColor = ThemeService.getTextColor(isDark);
            final captionColor = ThemeService.getCaptionColor(isDark);

            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: AlertDialog(
                backgroundColor: dialogBg.withOpacity(0.94),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text(
                  'Edit project',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PremiumInputField(
                        controller: _nameController,
                        label: 'Project name *',
                        hintText: 'Enter project name...',
                        prefixIcon: Icons.folder_rounded,
                      ),
                      const SizedBox(height: 12),
                      PremiumInputField(
                        controller: _descController,
                        label: 'Description',
                        hintText: 'Enter project description...',
                        prefixIcon: Icons.description_outlined,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: status,
                        dropdownColor: dialogBg,
                        decoration: const InputDecoration(
                          labelText: 'System status',
                        ),
                        items: ['Active', 'Completed', 'On Hold']
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    value,
                                    style: TextStyle(color: textColor),
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => status = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(context),
                    child:
                        Text('Cancel', style: TextStyle(color: captionColor)),
                  ),
                  PremiumButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = _nameController.text.trim();
                            if (name.isEmpty) return;

                            setDialogState(() => isSaving = true);
                            final payload = {
                              'name': name,
                              'description': _descController.text.trim(),
                              'status': status,
                            };
                            await _updateProject(project['_id'], payload);
                            project
                              ..['name'] = payload['name']
                              ..['description'] = payload['description']
                              ..['status'] = payload['status'];
                            sheetSetState(() {});
                            if (context.mounted) Navigator.pop(context);
                          },
                    backgroundColor: const Color(0xFF06B6D4),
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showProjectDetails(Map<String, dynamic> projectData) {
    _loadUsers();
    _projectTasks = [];
    _projectTasksLoaded = false;
    _taskFilter = 'All';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            final project = projectData['project'] as Map<String, dynamic>;
            final stats = projectData['stats'] as Map<String, dynamic>? ?? {};
            final role = (projectData['currentUserRole'] ??
                    _roleForUser(project, _currentUserId()))
                .toString();
            final canManage = _canManage(role);
            final isOwner = role == 'Owner';
            final isDark = ThemeService.isDarkMode.value;
            final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
            final textColor = ThemeService.getTextColor(isDark);
            final subTextColor = ThemeService.getSubTextColor(isDark);
            final captionColor = ThemeService.getCaptionColor(isDark);
            final borderColor = ThemeService.getBorderColor(isDark);
            const themeColor = Color(0xFF06B6D4);
            final workStatus = _projectStateLabel(projectData);
            final statusColor = _projectAccentColor(projectData);
            final memberCount = _projectMemberCount(projectData);
            final description = _projectDescription(projectData);

            return DefaultTabController(
              length: 4,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.88,
                  decoration: BoxDecoration(
                    color: dialogBg.withOpacity(0.92),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProjectDetailHeader(
                              name: project['name'] ?? 'Project',
                              description: description,
                              role: role,
                              workStatus: workStatus,
                              memberCount: memberCount,
                              progress: _projectProgress(projectData),
                              completedTasks:
                                  _projectCompletedTasks(projectData),
                              totalTasks: _projectTotalTasks(projectData),
                              statusColor: statusColor,
                              canShowMenu: isOwner,
                              onEdit: () => _showEditProjectDialog(
                                  projectData, sheetSetState),
                              onDelete: () => _showDeleteConfirmationDialog(
                                  project['_id'], project['name'] ?? ''),
                            ),
                            const SizedBox(height: 12),
                            TabBar(
                              labelColor: themeColor,
                              unselectedLabelColor: captionColor,
                              indicatorColor: themeColor,
                              labelStyle: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold),
                              tabs: const [
                                Tab(text: 'Overview'),
                                Tab(text: 'Tasks'),
                                Tab(text: 'Members'),
                                Tab(text: 'Chat'),
                              ],
                              onTap: (index) {
                                if (index == 1 && _projectTasks.isEmpty) {
                                  _loadProjectTasks(
                                      project['_id'], sheetSetState);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildProjectOverviewTab(
                              projectData,
                              project,
                              stats,
                              textColor,
                              subTextColor,
                              captionColor,
                              isDark,
                              sheetSetState,
                            ),
                            _buildProjectTasksTab(
                              project,
                              canManage,
                              textColor,
                              subTextColor,
                              captionColor,
                              sheetSetState,
                            ),
                            _buildProjectMembersTab(
                              projectData,
                              isOwner,
                              canManage,
                              textColor,
                              captionColor,
                              sheetSetState,
                            ),
                            _buildProjectChatTab(
                              project,
                              textColor,
                              subTextColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ignore: unused_element
  void _showLegacyProjectDetails(Map<String, dynamic> projectData) {
    _loadUsers();

    final project = projectData['project'];
    final members = project['members'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = ThemeService.isDarkMode.value;
        final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);
        final subTextColor = ThemeService.getSubTextColor(isDark);
        final captionColor = ThemeService.getCaptionColor(isDark);
        final borderColor = ThemeService.getBorderColor(isDark);

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: dialogBg.withOpacity(0.85),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(36),
                topRight: Radius.circular(36),
              ),
              border: Border.all(color: borderColor),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.15)
                          : Colors.black.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        project['name'] ??
                            LocaleService.tr('Dá»± Ã¡n khÃ´ng tÃªn',
                                en: 'Untitled project'),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_currentUser?['_id'] == project['owner']?['_id'] ||
                            _currentUser?['id'] == project['owner']?['id']) ...[
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent, size: 24),
                            onPressed: () => _showDeleteConfirmationDialog(
                                project['_id'], project['name'] ?? ''),
                          ),
                          const SizedBox(width: 8),
                        ],
                        PremiumButton.icon(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => ChatBottomSheet(
                                projectId: project['_id'],
                                projectName: project['name'] ??
                                    LocaleService.tr('Dá»± Ã¡n khÃ´ng tÃªn',
                                        en: 'Untitled project'),
                              ),
                            );
                          },
                          icon: Icons.chat_bubble_rounded,
                          label: LocaleService.tr('Chat', en: 'Chat'),
                          backgroundColor: const Color(0xFF06B6D4),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  project['description']?.toString().isNotEmpty == true
                      ? project['description']
                      : LocaleService.tr('KhÃ´ng cÃ³ mÃ´ táº£ chi tiáº¿t.',
                          en: 'No detailed description.'),
                  style: TextStyle(fontSize: 14, color: subTextColor),
                ),
                const SizedBox(height: 24),

                // Members Title & Add Member
                Text(
                    LocaleService.tr('THÃ€NH VIÃŠN Dá»° ÃN',
                        en: 'PROJECT MEMBERS'),
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: captionColor,
                        letterSpacing: 2)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PremiumInputField(
                        controller: _memberEmailController,
                        label: LocaleService.tr('Má»i thÃ nh viÃªn',
                            en: 'Invite member'),
                        hintText: LocaleService.tr(
                            'Nháº­p email thÃ nh viÃªn...',
                            en: 'Enter member email...'),
                        prefixIcon: Icons.mail_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    PremiumButton(
                      onPressed: () {
                        _addMember(project['_id']);
                        Navigator.pop(context);
                      },
                      backgroundColor: const Color(0xFF06B6D4),
                      child: Text(LocaleService.tr('Má»i', en: 'Invite'),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Members List
                Expanded(
                  child: ListView.builder(
                    itemCount: members.length + 1,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        final owner = project['owner'];
                        return FadeInSlide(
                          delayMs: 50,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: GlassCard(
                              borderRadius: 18,
                              padding: const EdgeInsets.all(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEAB308)
                                      .withOpacity(isDark ? 0.05 : 0.03),
                                  blurRadius: 10,
                                )
                              ],
                              child: Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Color(0xFFEAB308),
                                    radius: 18,
                                    child: Icon(Icons.star_rounded,
                                        size: 18, color: Colors.white),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              owner['name']
                                                          ?.toString()
                                                          .isNotEmpty ==
                                                      true
                                                  ? owner['name']
                                                  : owner['email']
                                                      .split('@')[0],
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: textColor),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEAB308)
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                  LocaleService.tr(
                                                      'CHá»¦ Dá»° ÃN',
                                                      en: 'OWNER'),
                                                  style: const TextStyle(
                                                      color: Color(0xFFEAB308),
                                                      fontSize: 8,
                                                      fontWeight:
                                                          FontWeight.w900)),
                                            )
                                          ],
                                        ),
                                        Text(owner['email'],
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: captionColor)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      final member = members[index - 1];
                      return FadeInSlide(
                        delayMs: index * 60,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: GlassCard(
                            borderRadius: 18,
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFF06B6D4),
                                  radius: 18,
                                  child: Icon(Icons.person_rounded,
                                      size: 18, color: Colors.white),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member['name']?.toString().isNotEmpty ==
                                              true
                                          ? member['name']
                                          : member['email'].split('@')[0],
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor),
                                    ),
                                    Text(member['email'],
                                        style: TextStyle(
                                            fontSize: 12, color: captionColor)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Suggested users list
                Text(
                  LocaleService.tr(
                    'Gá»¢I Ã THÃ€NH VIÃŠN',
                    en: 'SUGGESTED MEMBERS',
                  ),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: captionColor,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  height: 180,
                  child: _isLoadingUsers
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : _allUsers.isEmpty
                          ? Center(
                              child: Text(
                                LocaleService.tr(
                                  'KhÃ´ng cÃ³ ngÆ°á»i dÃ¹ng nÃ o',
                                  en: 'No users found',
                                ),
                                style: TextStyle(color: captionColor),
                              ),
                            )
                          : ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: _allUsers.length,
                              itemBuilder: (context, index) {
                                final user = _allUsers[index];

                                final alreadyMember = members
                                        .any((m) => m['_id'] == user['_id']) ||
                                    project['owner']['_id'] == user['_id'];

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Opacity(
                                    opacity: alreadyMember ? 0.5 : 1,
                                    child: GlassCard(
                                      borderRadius: 18,
                                      padding: const EdgeInsets.all(14),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor:
                                                const Color(0xFF06B6D4),
                                            backgroundImage: user['profile']
                                                            ?['avatarUrl'] !=
                                                        null &&
                                                    user['profile']['avatarUrl']
                                                        .toString()
                                                        .isNotEmpty
                                                ? NetworkImage(
                                                    user['profile']
                                                        ['avatarUrl'],
                                                  )
                                                : null,
                                            child: user['profile']
                                                            ?['avatarUrl'] ==
                                                        null ||
                                                    user['profile']['avatarUrl']
                                                        .toString()
                                                        .isEmpty
                                                ? const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user['name']
                                                              ?.toString()
                                                              .isNotEmpty ==
                                                          true
                                                      ? user['name']
                                                      : user['email']
                                                          .split('@')[0],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor,
                                                  ),
                                                ),
                                                Text(
                                                  user['email'],
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: captionColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          alreadyMember
                                              ? Text(
                                                  LocaleService.tr(
                                                    'ÄÃ£ tham gia',
                                                    en: 'Joined',
                                                  ),
                                                  style: const TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                )
                                              : PremiumButton(
                                                  onPressed: () async {
                                                    _memberEmailController
                                                        .text = user['email'];

                                                    await _addMember(
                                                        project['_id']);
                                                  },
                                                  backgroundColor:
                                                      const Color(0xFF06B6D4),
                                                  child: Text(
                                                    LocaleService.tr(
                                                      'ThÃªm',
                                                      en: 'Add',
                                                    ),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
