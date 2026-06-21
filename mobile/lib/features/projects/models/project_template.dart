import 'package:flutter/material.dart';

import 'project_type.dart';

/// Pre-built project blueprint used by [CreateProjectSheet].
///
/// Selecting a template pre-fills the project name / description / type and
/// queues a list of milestones to be created right after the project itself
/// is persisted. Pure client-side data — no backend table required.
class ProjectTemplate {
  final String id;
  final String name;
  final String tagline;
  final IconData icon;
  final Color color;
  final String projectName;
  final String projectDescription;
  final ProjectType projectType;
  final Duration? defaultDeadlineOffset;
  final List<ProjectTemplateMilestone> milestones;

  const ProjectTemplate({
    required this.id,
    required this.name,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.projectName,
    required this.projectDescription,
    required this.projectType,
    required this.milestones,
    this.defaultDeadlineOffset,
  });

  /// Static catalog. Add new templates here — UI auto-renders them.
  static const List<ProjectTemplate> catalog = [
    ProjectTemplate(
      id: 'sprint-2w',
      name: '2-Week Sprint',
      tagline: 'Plan, build, review, ship.',
      icon: Icons.bolt_rounded,
      color: Color(0xFF06B6D4),
      projectName: 'New Sprint',
      projectDescription:
          'Two-week iteration with planning, execution, review and demo gates.',
      projectType: ProjectType.team,
      defaultDeadlineOffset: Duration(days: 14),
      milestones: [
        ProjectTemplateMilestone(
          title: 'Sprint planning',
          description:
              'Backlog grooming, capacity check, commit to sprint goal.',
          dayOffset: 0,
        ),
        ProjectTemplateMilestone(
          title: 'Mid-sprint check-in',
          description: 'Halfway sync — adjust scope if needed.',
          dayOffset: 7,
        ),
        ProjectTemplateMilestone(
          title: 'Sprint review + demo',
          description: 'Show what shipped, gather feedback.',
          dayOffset: 13,
        ),
        ProjectTemplateMilestone(
          title: 'Retrospective',
          description: 'What went well, what to improve next sprint.',
          dayOffset: 14,
        ),
      ],
    ),
    ProjectTemplate(
      id: 'capstone',
      name: 'Capstone Project',
      tagline: 'University thesis from kickoff to defense.',
      icon: Icons.school_rounded,
      color: Color(0xFF10B981),
      projectName: 'Capstone',
      projectDescription:
          'End-to-end capstone milestones from topic approval to final defense.',
      projectType: ProjectType.study,
      defaultDeadlineOffset: Duration(days: 90),
      milestones: [
        ProjectTemplateMilestone(
          title: 'Topic approval',
          description: 'Pitch topic, lock scope with advisor.',
          dayOffset: 7,
        ),
        ProjectTemplateMilestone(
          title: 'Literature review',
          description: 'Survey related work and write the references section.',
          dayOffset: 21,
        ),
        ProjectTemplateMilestone(
          title: 'Prototype demo',
          description: 'Working slice that proves the core idea.',
          dayOffset: 50,
        ),
        ProjectTemplateMilestone(
          title: 'Draft report',
          description: 'Full report draft sent to advisor for review.',
          dayOffset: 75,
        ),
        ProjectTemplateMilestone(
          title: 'Final defense',
          description: 'Slide deck, demo and Q&A.',
          dayOffset: 90,
        ),
      ],
    ),
    ProjectTemplate(
      id: 'product-launch',
      name: 'Product Launch',
      tagline: 'Build, beta, ship.',
      icon: Icons.rocket_launch_rounded,
      color: Color(0xFFF59E0B),
      projectName: 'Launch',
      projectDescription:
          'Coordinate engineering, marketing and support for a public launch.',
      projectType: ProjectType.work,
      defaultDeadlineOffset: Duration(days: 45),
      milestones: [
        ProjectTemplateMilestone(
          title: 'Feature complete',
          description: 'All scoped features merged to main.',
          dayOffset: 20,
        ),
        ProjectTemplateMilestone(
          title: 'Internal beta',
          description: 'Dogfood with the team, collect feedback.',
          dayOffset: 28,
        ),
        ProjectTemplateMilestone(
          title: 'Marketing assets ready',
          description: 'Landing page, social posts, demo video.',
          dayOffset: 35,
        ),
        ProjectTemplateMilestone(
          title: 'Public launch',
          description: 'Press, social rollout, monitor metrics.',
          dayOffset: 45,
        ),
      ],
    ),
    ProjectTemplate(
      id: 'onboarding',
      name: 'Onboarding Plan',
      tagline: 'First 30 days for a new hire.',
      icon: Icons.person_add_alt_rounded,
      color: Color(0xFF8B5CF6),
      projectName: '30-day Onboarding',
      projectDescription:
          'Structured onboarding for a new teammate — setup, ramp-up, first project.',
      projectType: ProjectType.team,
      defaultDeadlineOffset: Duration(days: 30),
      milestones: [
        ProjectTemplateMilestone(
          title: 'Day 1 setup',
          description: 'Accounts, hardware, welcome lunch.',
          dayOffset: 1,
        ),
        ProjectTemplateMilestone(
          title: 'First week shadowing',
          description: 'Pair with senior teammates on real tasks.',
          dayOffset: 7,
        ),
        ProjectTemplateMilestone(
          title: 'First shipped change',
          description: 'Small, owned PR merged to main.',
          dayOffset: 14,
        ),
        ProjectTemplateMilestone(
          title: '30-day review',
          description: 'Feedback both ways, next-90-day plan.',
          dayOffset: 30,
        ),
      ],
    ),
  ];

  /// Materialise the template's milestones into concrete dates anchored on
  /// [start]. Returns title + description + targetDate triples ready to be
  /// pushed through `ProjectMilestoneService.addMilestone`.
  List<MaterializedMilestone> materializeMilestones(DateTime start) {
    return milestones
        .map(
          (m) => MaterializedMilestone(
            title: m.title,
            description: m.description,
            targetDate: start.add(Duration(days: m.dayOffset)),
          ),
        )
        .toList(growable: false);
  }
}

/// Plan-only milestone shape. Day offset is relative to project start.
class ProjectTemplateMilestone {
  final String title;
  final String description;
  final int dayOffset;

  const ProjectTemplateMilestone({
    required this.title,
    required this.description,
    required this.dayOffset,
  });
}

/// Concrete milestone with absolute target date, ready for persistence.
class MaterializedMilestone {
  final String title;
  final String description;
  final DateTime targetDate;

  const MaterializedMilestone({
    required this.title,
    required this.description,
    required this.targetDate,
  });
}
