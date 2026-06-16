part of project_screen;

extension _ProjectScreenSections on _ProjectScreenState {
  // ──────────────────────────────────────────────
  // Tab builders — delegates sang widget files
  // ──────────────────────────────────────────────

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
      final allowMembers = project['allowMembersToCreateTasks'] == true;
      final canManage = _canManage(role);
      final canAddTask = canManage || allowMembers;

      title = 'Get started';
      text = canAddTask
          ? 'No tasks have been created yet. Create the first task to start tracking progress.'
          : 'No tasks have been created yet. Ask a manager to assign the first task.';
      cta = canAddTask ? 'Add first task' : '';
      action = canAddTask
          ? () => _showCreateProjectTaskDialog(project, sheetSetState)
          : () {};
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

  // ignore: unused_element
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
    final allowMembers = project['allowMembersToCreateTasks'] == true;
    final canAddTask = canManage || allowMembers;

    return TasksTab(
      tasks: _projectTasks,
      selectedFilter: _taskFilter,
      isLoading: _isLoadingProjectTasks,
      tasksLoaded: _projectTasksLoaded,
      canManage: canManage,
      canAddTask: canAddTask,
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

  // ──────────────────────────────────────────────
  // Project details bottom sheet
  // ──────────────────────────────────────────────

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
            final stats =
                projectData['stats'] as Map<String, dynamic>? ?? {};
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
                    color: dialogBg.withValues(alpha: 0.92),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    border: Border.all(color: borderColor),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                              canLeave: !isOwner,
                              onEdit: () => _showEditProjectDialog(
                                  projectData, sheetSetState),
                              onDelete: () => _showDeleteConfirmationDialog(
                                  project['_id'], project['name'] ?? ''),
                              onLeave: () => _showLeaveConfirmationDialog(
                                  project['_id'], project['name'] ?? ''),
                            ),
                            const SizedBox(height: 12),
                            TabBar(
                              labelColor: themeColor,
                              unselectedLabelColor: captionColor,
                              indicatorColor: themeColor,
                              labelStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
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
}
