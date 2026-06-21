import 'package:flutter_test/flutter_test.dart';
import 'package:prm_app/features/projects/models/project_template.dart';

void main() {
  group('ProjectTemplate.catalog', () {
    test('has 4 templates and every one has at least 1 milestone', () {
      expect(ProjectTemplate.catalog.length, 4);
      for (final template in ProjectTemplate.catalog) {
        expect(template.milestones, isNotEmpty,
            reason: '${template.id} should ship with milestones');
      }
    });

    test('each template id is unique', () {
      final ids = ProjectTemplate.catalog.map((t) => t.id).toSet();
      expect(ids.length, ProjectTemplate.catalog.length);
    });
  });

  group('ProjectTemplate.materializeMilestones', () {
    test('anchors targetDate to start + dayOffset', () {
      final template = ProjectTemplate.catalog
          .firstWhere((t) => t.id == 'sprint-2w');
      final start = DateTime(2026, 6, 20);
      final materialized = template.materializeMilestones(start);

      expect(materialized.length, template.milestones.length);
      for (var i = 0; i < materialized.length; i++) {
        final expectedDay = start.add(
          Duration(days: template.milestones[i].dayOffset),
        );
        expect(materialized[i].targetDate, expectedDay);
        expect(materialized[i].title, template.milestones[i].title);
      }
    });

    test('first sprint milestone lands on the start date itself', () {
      final template = ProjectTemplate.catalog
          .firstWhere((t) => t.id == 'sprint-2w');
      final start = DateTime(2026, 6, 20);
      final materialized = template.materializeMilestones(start);
      expect(materialized.first.targetDate, start);
    });
  });
}
