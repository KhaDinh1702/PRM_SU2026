part of project_screen;

extension _ProjectScreenSections on _ProjectScreenState {
  // ──────────────────────────────────────────────
  // Tab builders — delegates sang widget files
  // ──────────────────────────────────────────────

  Widget _buildProjectOverviewTab(
    ProjectModel projectData,
    ProjectDetails project,
    ProjectStats stats,
    Color textColor,
    Color subTextColor,
    Color captionColor,
    bool isDark,
    StateSetter sheetSetState,
  ) {
    final total = projectData.totalTasks;
    final completed = projectData.completedTasks;
    final progress = projectData.progress;
    final memberCount = projectData.memberCount;
    final role = projectData.role;
    final workStatus = projectData.stateLabel;
    final statusColor = projectData.accentColor;
    final openTasks = projectData.openTasks;

    String title;
    String text;
    String cta;
    VoidCallback action;

    if (projectData.isOverdue) {
      title = 'Needs attention';
      text = '$openTasks open tasks need review. Start with overdue work.';
      cta = 'Review overdue tasks';
      action = () => DefaultTabController.of(context).animateTo(1);
    } else if (total == 0) {
      final allowMembers = project.allowMembersToCreateTasks;
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
      description: projectData.description,
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
    ProjectDetails project,
    bool canManage,
    Color textColor,
    Color subTextColor,
    Color captionColor,
    StateSetter sheetSetState,
  ) {
    final allowMembers = project.allowMembersToCreateTasks;
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
      onLoadTasks: () => _loadProjectTasks(project.id, sheetSetState),
      assigneeName: (assignee) => _assigneeDisplayName(assignee, project),
      canUpdateTask: (task) {
        final assignee = task['assignedTo'] ?? task['user'];
        return canManage || _itemId(assignee) == _currentUserId();
      },
      onEditTask: (task) =>
          _showEditProjectTaskDialog(project, task, sheetSetState),
      onUpdateStatus: (task, status) => _updateProjectTaskStatus(
        project.id,
        task['_id'],
        status,
        sheetSetState,
      ),
    );
  }

  Widget _buildProjectMembersTab(
    ProjectModel projectData,
    bool isOwner,
    bool canManage,
    Color textColor,
    Color captionColor,
    StateSetter sheetSetState,
  ) {
    final project = projectData.project;
    final participants = _projectParticipants(project);
    final owners = participants
        .where((user) => _roleForUser(project, user.id) == 'Owner')
        .toList();
    final managers = participants
        .where((user) => _roleForUser(project, user.id) == 'Manager')
        .toList();
    final regularMembers = participants
        .where((user) => _roleForUser(project, user.id) == 'Member')
        .toList();

    final invitedUserIds = {
      ...projectData.pendingInvitationUserIds,
      ...(_localPendingInviteIds[project.id] ?? const <String>{}),
    };
    final participantIds = participants.map((p) => p.id).toSet();
    final invitedUserIdsFiltered = invitedUserIds.where((id) => !participantIds.contains(id)).toList();

    final invitedMembers = invitedUserIdsFiltered.map((id) {
      final matchedUser = _allUsers.firstWhere(
        (u) => _itemId(u) == id,
        orElse: () => null,
      );
      if (matchedUser != null) {
        return matchedUser;
      }
      return {
        '_id': id,
        'name': '',
        'email': 'Invited User ($id)',
      };
    }).toList();

    return MembersTab(
      owners: owners,
      managers: managers,
      members: regularMembers,
      invited: invitedMembers,
      canInvite: canManage,
      canEditRoles: isOwner,
      onRoleChanged: (user, role) async {
        final userId = _itemId(user);
        if (userId.isEmpty) return;
        await _updateMemberRole(
          project.id,
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
                  final invitedUserId = await _addMember(project.id);
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
    ProjectDetails project,
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
            projectId: project.id,
            projectName: project.name,
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────
  // Project details bottom sheet
  // ──────────────────────────────────────────────

  void _showProjectDetails(ProjectModel initialProjectData) {
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
            // Find projectData from provider to keep it updated dynamically
            final projectData = context.watch<ProjectProvider>().projects.firstWhere(
                  (p) => p.project.id == initialProjectData.project.id,
                  orElse: () => initialProjectData,
                );

            final project = projectData.project;
            final stats = projectData.stats;
            final role = projectData.role;
            final canManage = _canManage(role);
            final isOwner = role == 'Owner';
            final isDark = ThemeService.isDarkMode.value;
            final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
            final textColor = ThemeService.getTextColor(isDark);
            final subTextColor = ThemeService.getSubTextColor(isDark);
            final captionColor = ThemeService.getCaptionColor(isDark);
            final borderColor = ThemeService.getBorderColor(isDark);
            const themeColor = Color(0xFF06B6D4);
            final workStatus = projectData.stateLabel;
            final statusColor = projectData.accentColor;
            final memberCount = projectData.memberCount;
            final description = projectData.description;

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
                              name: project.name,
                              description: description,
                              role: role,
                              workStatus: workStatus,
                              memberCount: memberCount,
                              progress: projectData.progress,
                              completedTasks:
                                  projectData.completedTasks,
                              totalTasks: projectData.totalTasks,
                              statusColor: statusColor,
                              canShowMenu: isOwner,
                              canLeave: !isOwner,
                              onEdit: () => _showEditProjectDialog(
                                  projectData, sheetSetState),
                              onDelete: () => _showDeleteConfirmationDialog(
                                  project.id, project.name),
                              onLeave: () => _showLeaveConfirmationDialog(
                                  project.id, project.name),
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
                                      project.id, sheetSetState);
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
