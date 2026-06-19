class ProjectMilestone {
  final String id;
  final String title;
  final String? description;
  final DateTime? targetDate;
  final bool isCompleted;

  const ProjectMilestone({
    required this.id,
    required this.title,
    this.description,
    this.targetDate,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'targetDate': targetDate?.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory ProjectMilestone.fromJson(Map<String, dynamic> json) {
    return ProjectMilestone(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Milestone',
      description: json['description']?.toString(),
      targetDate: json['targetDate'] != null
          ? DateTime.tryParse(json['targetDate'].toString())?.toLocal()
          : null,
      isCompleted: json['isCompleted'] == true,
    );
  }

  ProjectMilestone copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? targetDate,
    bool? isCompleted,
  }) {
    return ProjectMilestone(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
