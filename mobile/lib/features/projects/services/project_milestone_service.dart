import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/project_milestone.dart';
import '../models/project_model.dart';

class ProjectMilestoneService {
  const ProjectMilestoneService();

  String _key(String projectId) => 'project_milestones_$projectId';

  Future<List<ProjectMilestone>> loadMilestones({
    required String projectId,
    required ProjectModel projectData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(projectId));
    if (raw != null) {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map(ProjectMilestone.fromJson)
          .toList();
    }
    return _defaultMilestones(projectData);
  }

  Future<void> saveMilestones(
    String projectId,
    List<ProjectMilestone> milestones,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(milestones.map((m) => m.toJson()).toList());
    await prefs.setString(_key(projectId), encoded);
  }

  Future<ProjectMilestone> addMilestone({
    required String projectId,
    required List<ProjectMilestone> current,
    required String title,
    DateTime? targetDate,
  }) async {
    final milestone = ProjectMilestone(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      targetDate: targetDate,
    );
    final updated = [...current, milestone];
    await saveMilestones(projectId, updated);
    return milestone;
  }

  List<ProjectMilestone> _defaultMilestones(ProjectModel projectData) {
    final project = projectData.project;
    final progress = projectData.progress;
    final created = project.createdAt ?? DateTime.now();
    final deadline = project.deadline;

    return [
      ProjectMilestone(
        id: 'created',
        title: 'Project Created',
        targetDate: created,
        isCompleted: true,
      ),
      ProjectMilestone(
        id: 'backend',
        title: 'Backend Complete',
        isCompleted: progress >= 30,
      ),
      ProjectMilestone(
        id: 'ui',
        title: 'UI Complete',
        isCompleted: progress >= 60,
      ),
      ProjectMilestone(
        id: 'testing',
        title: 'Testing',
        isCompleted: progress >= 85,
      ),
      ProjectMilestone(
        id: 'deployment',
        title: 'Deployment',
        targetDate: deadline,
        isCompleted: progress >= 100,
      ),
    ];
  }
}
