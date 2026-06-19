import 'package:flutter/material.dart';

import '../../models/project_activity.dart';
import '../../models/project_model.dart';
import 'project_activity_feed.dart';
import 'project_hero_card.dart';
import 'project_insights_grid.dart';
import 'project_next_task_card.dart';
import 'project_team_avatars.dart';

class OverviewTab extends StatelessWidget {
  final ProjectModel projectData;
  final dynamic nextTask;
  final String nextTaskAssignee;
  final List<ProjectActivity> activities;
  final List<ProjectMember> teamMembers;
  final Map<String, String> memberRoles;
  final int activeDays;
  final VoidCallback? onOpenNextTask;
  final VoidCallback? onStartNextTask;
  final VoidCallback? onCreateTask;
  final VoidCallback? onInviteMember;
  final VoidCallback? onManageMembers;

  const OverviewTab({
    super.key,
    required this.projectData,
    required this.nextTask,
    required this.nextTaskAssignee,
    required this.activities,
    required this.teamMembers,
    required this.memberRoles,
    required this.activeDays,
    this.onOpenNextTask,
    this.onStartNextTask,
    this.onCreateTask,
    this.onInviteMember,
    this.onManageMembers,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        ProjectHeroCard(
          name: projectData.name,
          statusLabel: projectData.stateLabel,
          statusColor: projectData.accentColor,
          progress: projectData.progress,
          completedTasks: projectData.completedTasks,
          totalTasks: projectData.totalTasks,
          dueDate: projectData.deadline,
          memberCount: projectData.memberCount,
        ),
        const SizedBox(height: 16),
        ProjectNextTaskCard(
          task: nextTask,
          assigneeName: nextTaskAssignee,
          onOpenTask: onOpenNextTask,
          onMarkInProgress: onStartNextTask,
          onCreateTask: onCreateTask,
        ),
        const SizedBox(height: 20),
        ProjectInsightsGrid(
          totalTasks: projectData.totalTasks,
          memberCount: projectData.memberCount,
          activeDays: activeDays,
          status: projectData.stateLabel,
          statusColor: projectData.accentColor,
        ),
        const SizedBox(height: 20),
        ProjectActivityFeed(activities: activities),
        const SizedBox(height: 20),
        ProjectTeamAvatars(
          members: teamMembers,
          memberRoles: memberRoles,
          onInvite: onInviteMember,
          onManage: onManageMembers,
        ),
      ],
    );
  }
}
