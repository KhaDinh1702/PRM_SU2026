import '../models/project_activity.dart';
import '../models/project_model.dart';

class ProjectActivityBuilder {
  static List<ProjectActivity> build({
    required ProjectModel projectData,
    required List<dynamic> tasks,
    required List<ProjectMember> members,
  }) {
    final activities = <ProjectActivity>[];

    for (final task in tasks) {
      if (task is! Map) continue;
      final title = task['title']?.toString() ?? 'Task';
      final assignee = _nameFromRef(task['assignedTo'] ?? task['user']);
      final createdAt = DateTime.tryParse(
            task['createdAt']?.toString() ?? '',
          ) ??
          projectData.project.createdAt;

      if (createdAt != null) {
        activities.add(
          ProjectActivity(
            id: 'create-${task['_id']}',
            type: ProjectActivityType.taskCreated,
            message: '$assignee created $title',
            timestamp: createdAt,
            actorName: assignee,
          ),
        );
      }

      if ((task['status'] ?? '') == 'Completed') {
        final completedAt = DateTime.tryParse(
              task['completedAt']?.toString() ?? task['updatedAt']?.toString() ?? '',
            ) ??
            createdAt ??
            DateTime.now();
        activities.add(
          ProjectActivity(
            id: 'done-${task['_id']}',
            type: ProjectActivityType.taskCompleted,
            message: '$assignee completed $title',
            timestamp: completedAt,
            actorName: assignee,
          ),
        );
      }
    }

    if (members.length > 1) {
      final joined = members.skip(1).take(3);
      for (final member in joined) {
        activities.add(
          ProjectActivity(
            id: 'member-${member.id}',
            type: ProjectActivityType.memberJoined,
            message: '${member.name.isNotEmpty ? member.name : member.email} joined the project',
            timestamp: projectData.project.createdAt ?? DateTime.now(),
            actorName: member.name,
          ),
        );
      }
    }

    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return activities.take(8).toList();
  }

  static String _nameFromRef(dynamic ref) {
    if (ref is Map) {
      final name = ref['name']?.toString();
      if (name != null && name.isNotEmpty) return name;
      final email = ref['email']?.toString();
      if (email != null && email.isNotEmpty) return email.split('@').first;
    }
    return 'Someone';
  }

  static String relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
