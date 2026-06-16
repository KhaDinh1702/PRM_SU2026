part of project_screen;

extension _ProjectScreenDialogs on _ProjectScreenState {
  // ──────────────────────────────────────────────
  // Date / Time pickers
  // ──────────────────────────────────────────────

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

  bool _isDueTimeInPast(DateTime date, TimeOfDay time) {
    final now = DateTime.now();
    final dueAt =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    return dueAt.isBefore(now);
  }

  // ──────────────────────────────────────────────
  // Reusable UI builders for dialogs
  // ──────────────────────────────────────────────

  // ignore: unused_element
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
              ? const Color(0xFF06B6D4).withValues(alpha: 0.14)
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

  // ignore: unused_element
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
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }

  Widget _buildRoundedDropdown<T>({
    required T? value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required Color dialogBg,
    required Color textColor,
  }) {
    // ignore: deprecated_member_use
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: ThemeService.isDarkMode.value
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.03),
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: ThemeService.isDarkMode.value
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.black.withValues(alpha: 0.03),
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
                  child:
                      Text(priority, style: TextStyle(color: textColor)),
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
    final selectedValue =
        items.any((item) => item.value == _selectedAssigneeId)
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

  // ──────────────────────────────────────────────
  // Create Task Dialog
  // ──────────────────────────────────────────────

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
                backgroundColor: dialogBg.withValues(alpha: 0.94),
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
                        label: LocaleService.tr('Ten task *',
                            en: 'Task title *'),
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

  // ──────────────────────────────────────────────
  // Edit Task Dialog
  // ──────────────────────────────────────────────

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
                backgroundColor: dialogBg.withValues(alpha: 0.94),
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
                        label: LocaleService.tr('Ten task *',
                            en: 'Task title *'),
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
                    onPressed:
                        isSaving ? null : () => Navigator.pop(context),
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
                                    'Vui lòng nhập đầy đủ thông tin.',
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
                                'description':
                                    _taskDescController.text.trim(),
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

  // ──────────────────────────────────────────────
  // Edit Project Dialog
  // ──────────────────────────────────────────────

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
                backgroundColor: dialogBg.withValues(alpha: 0.94),
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
                      // ignore: deprecated_member_use
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
                    onPressed:
                        isSaving ? null : () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: TextStyle(color: captionColor)),
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
}
