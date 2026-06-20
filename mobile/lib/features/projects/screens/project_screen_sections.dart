part of project_screen;

extension _ProjectScreenSections on _ProjectScreenState {
  Widget _buildProjectOverviewTab(
    ProjectModel projectData,
    ProjectDetails project,
    bool canManage,
    bool isOwner,
    Color textColor,
    Color captionColor,
    StateSetter sheetSetState,
  ) {
    final participants = _projectParticipants(project);
    final teamMembers = participants
        .map((p) => ProjectMember(
              id: p.id,
              name: p.name,
              email: p.email,
            ))
        .toList();
    final nextTask = ProjectBoardUtils.pickNextTask(_projectTasks);
    final nextAssignee = nextTask == null
        ? ''
        : _assigneeDisplayName(nextTask.assignedTo, project);
    final allowMembers = project.allowMembersToCreateTasks;
    final canAddTask = canManage || allowMembers;

    return OverviewTab(
      projectData: projectData,
      nextTask: nextTask,
      nextTaskAssignee: nextAssignee.isEmpty ? 'Unassigned' : nextAssignee,
      activities: ProjectActivityBuilder.build(
        projectData: projectData,
        tasks: _projectTasks.map((t) => t.toMap()).toList(),
        members: teamMembers,
      ),
      teamMembers: teamMembers,
      memberRoles: _memberRolesMap(project),
      activeDays: _activeProjectDays(project),
      onOpenNextTask: nextTask == null
          ? null
          : () => _showEditProjectTaskDialog(
                project, nextTask.toMap(), sheetSetState),
      onStartNextTask: nextTask == null
          ? null
          : () => _updateProjectTaskStatus(
                project.id,
                nextTask.id,
                'In Progress',
                sheetSetState,
              ),
      onCreateTask: canAddTask
          ? () => _showCreateProjectTaskDialog(project, sheetSetState)
          : null,
      onInviteMember: canManage
          ? () => _showInviteMemberDialog(project, projectData, sheetSetState)
          : null,
      onManageMembers: () => _showMembersManagementSheet(
        projectData,
        isOwner,
        canManage,
        textColor,
        captionColor,
        sheetSetState,
      ),
    );
  }

  Widget _buildProjectBoardTab(
    ProjectDetails project,
    bool canManage,
    StateSetter sheetSetState,
  ) {
    final allowMembers = project.allowMembersToCreateTasks;
    final canAddTask = canManage || allowMembers;
    return BoardTab(
      tasks: _projectTasks,
      reviewTaskIds: _reviewTaskIds,
      isLoading: _isLoadingProjectTasks,
      tasksLoaded: _projectTasksLoaded,
      assigneeName: (assignee) => _assigneeDisplayName(assignee, project),
      canUpdateTask: (task) {
        return canManage ||
            _itemId(task.assignedTo) == _currentUserId();
      },
      onOpenTask: (task) =>
          _showEditProjectTaskDialog(project, task.toMap(), sheetSetState),
      onMarkComplete: (task) =>
          _handleBoardComplete(project.id, task.toMap(), sheetSetState),
      onMoveToNextStatus: (task) =>
          _handleBoardAdvance(project.id, task.toMap(), sheetSetState),
      onLoadTasks: () => _loadProjectTasks(project.id, sheetSetState),
      onCreateTask: canAddTask
          ? () => _showCreateProjectTaskDialog(project, sheetSetState)
          : null,
    );
  }

  Widget _buildProjectTimelineTab(
    ProjectDetails project,
    ProjectModel projectData,
    bool canManage,
    StateSetter sheetSetState,
  ) {
    return ProjectTimelineTab(
      milestones: _projectMilestones,
      isLoading: _milestonesLoading,
      onCreateMilestone: canManage
          ? () => _showCreateMilestoneDialog(
                project, projectData, sheetSetState)
          : null,
      onEditMilestone: canManage
          ? (milestone) => _showEditMilestoneSheet(
                project, projectData, milestone, sheetSetState)
          : null,
      onDeleteMilestone: canManage
          ? (milestone) => _confirmDeleteMilestone(
                project, projectData, milestone, sheetSetState)
          : null,
      onToggleComplete: canManage
          ? (milestone) async {
              await _milestoneService.toggleCompleted(
                projectId: project.id,
                current: _projectMilestones,
                milestoneId: milestone.id,
              );
              await _loadProjectMilestones(projectData, sheetSetState);
            }
          : null,
    );
  }

  Future<void> _showInviteMemberDialog(
    ProjectDetails project,
    ProjectModel projectData,
    StateSetter sheetSetState,
  ) async {
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
  }

  Future<void> _showCreateMilestoneDialog(
    ProjectDetails project,
    ProjectModel projectData,
    StateSetter sheetSetState,
  ) async {
    final result = await MilestoneCreateSheet.show(context);
    if (result == null) return;
    await _milestoneService.addMilestone(
      projectId: project.id,
      current: _projectMilestones,
      title: result.title,
      description: result.description.isEmpty ? null : result.description,
      targetDate: result.targetDate,
    );
    await _loadProjectMilestones(projectData, sheetSetState);
  }

  Future<void> _showEditMilestoneSheet(
    ProjectDetails project,
    ProjectModel projectData,
    ProjectMilestone milestone,
    StateSetter sheetSetState,
  ) async {
    final result = await MilestoneCreateSheet.show(context, initial: milestone);
    if (result == null) return;
    await _milestoneService.updateMilestone(
      projectId: project.id,
      current: _projectMilestones,
      milestoneId: milestone.id,
      title: result.title,
      description: result.description.isEmpty ? null : result.description,
      targetDate: result.targetDate,
      clearTargetDate: result.targetDate == null,
    );
    await _loadProjectMilestones(projectData, sheetSetState);
  }

  Future<void> _confirmDeleteMilestone(
    ProjectDetails project,
    ProjectModel projectData,
    ProjectMilestone milestone,
    StateSetter sheetSetState,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete milestone?'),
        content: Text(
          'Remove "${milestone.title}" from the timeline? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _milestoneService.deleteMilestone(
      projectId: project.id,
      current: _projectMilestones,
      milestoneId: milestone.id,
    );
    await _loadProjectMilestones(projectData, sheetSetState);
  }

  void _showMembersManagementSheet(
    ProjectModel projectData,
    bool isOwner,
    bool canManage,
    Color textColor,
    Color captionColor,
    StateSetter sheetSetState,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = ThemeService.isDarkMode.value;
        final dialogBg = ThemeService.getDialogBackgroundColor(isDark);
        final borderColor = ThemeService.getBorderColor(isDark);

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.72,
            decoration: BoxDecoration(
              color: dialogBg.withValues(alpha: 0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: borderColor),
            ),
            child: _buildProjectMembersTab(
              projectData,
              isOwner,
              canManage,
              textColor,
              captionColor,
              sheetSetState,
            ),
          ),
        );
      },
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
    final invitedUserIdsFiltered =
        invitedUserIds.where((id) => !participantIds.contains(id)).toList();

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
      onInvite: () => _showInviteMemberDialog(
        project,
        projectData,
        sheetSetState,
      ),
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

  void _showProjectDetails(ProjectModel initialProjectData) {
    _loadUsers();
    _projectTasks = [];
    _projectTasksLoaded = false;
    _projectMilestones = [];
    _reviewTaskIds.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, sheetSetState) {
            final projectData =
                context.watch<ProjectProvider>().projects.firstWhere(
                      (p) => p.project.id == initialProjectData.project.id,
                      orElse: () => initialProjectData,
                    );

            final project = projectData.project;
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
            final allowMembers = project.allowMembersToCreateTasks;
            final canAddTask = canManage || allowMembers;

            if (!_projectTasksLoaded && !_isLoadingProjectTasks) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadProjectTasks(project.id, sheetSetState);
              });
            }
            if (_projectMilestones.isEmpty && !_milestonesLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _loadProjectMilestones(projectData, sheetSetState);
              });
            }

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
                  child: Scaffold(
                    backgroundColor: Colors.transparent,
                    floatingActionButton: (canAddTask || canManage)
                        ? ProjectDetailFab(
                            onCreateTask: canAddTask
                                ? () => _showCreateProjectTaskDialog(
                                      project,
                                      sheetSetState,
                                    )
                                : () {},
                            onCreateMilestone: () =>
                                _showCreateMilestoneDialog(
                              project,
                              projectData,
                              sheetSetState,
                            ),
                            onInviteMember: canManage
                                ? () => _showInviteMemberDialog(
                                      project,
                                      projectData,
                                      sheetSetState,
                                    )
                                : () {},
                          )
                        : null,
                    body: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
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
                                completedTasks: projectData.completedTasks,
                                totalTasks: projectData.totalTasks,
                                statusColor: statusColor,
                                canShowMenu: isOwner,
                                canLeave: !isOwner,
                                onEdit: () => _showEditProjectDialog(
                                    projectData, sheetSetState),
                                onDelete: () =>
                                    _showDeleteConfirmationDialog(
                                  project.id,
                                  project.name,
                                ),
                                onLeave: () => _showLeaveConfirmationDialog(
                                  project.id,
                                  project.name,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TabBar(
                                labelColor: themeColor,
                                unselectedLabelColor: captionColor,
                                indicatorColor: themeColor,
                                labelStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                tabs: const [
                                  Tab(text: 'Overview'),
                                  Tab(text: 'Board'),
                                  Tab(text: 'Timeline'),
                                  Tab(text: 'Chat'),
                                ],
                                onTap: (index) {
                                  if ((index == 0 || index == 1) &&
                                      !_projectTasksLoaded) {
                                    _loadProjectTasks(
                                        project.id, sheetSetState);
                                  }
                                  if (index == 2 &&
                                      _projectMilestones.isEmpty) {
                                    _loadProjectMilestones(
                                        projectData, sheetSetState);
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
                                canManage,
                                isOwner,
                                textColor,
                                captionColor,
                                sheetSetState,
                              ),
                              _buildProjectBoardTab(
                                project,
                                canManage,
                                sheetSetState,
                              ),
                              _buildProjectTimelineTab(
                                project,
                                projectData,
                                canManage,
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
              ),
            );
          },
        );
      },
    );
  }
}
