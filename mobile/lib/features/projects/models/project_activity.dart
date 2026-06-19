enum ProjectActivityType {
  taskCompleted,
  taskCreated,
  memberJoined,
  milestoneAdded,
  projectUpdated,
}

class ProjectActivity {
  final String id;
  final ProjectActivityType type;
  final String message;
  final DateTime timestamp;
  final String? actorName;

  const ProjectActivity({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    this.actorName,
  });
}
