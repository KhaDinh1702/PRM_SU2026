import 'package:flutter_test/flutter_test.dart';
import 'package:prm_app/features/projects/models/project_create_draft.dart';
import 'package:prm_app/features/projects/models/project_type.dart';

void main() {
  group('ProjectCreateDraft.validate', () {
    test('rejects empty name', () {
      final v = const ProjectCreateDraft(name: '').validate();
      expect(v.isValid, isFalse);
      expect(v.nameError, isNotNull);
    });

    test('rejects name shorter than minimum length', () {
      final v = const ProjectCreateDraft(name: 'ab').validate();
      expect(v.isValid, isFalse);
      expect(v.nameError, contains('at least'));
    });

    test('rejects deadline in the past', () {
      final v = ProjectCreateDraft(
        name: 'My Project',
        deadline: DateTime.now().subtract(const Duration(days: 2)),
      ).validate();
      expect(v.deadlineError, isNotNull);
    });

    test('rejects malformed invite emails', () {
      final v = const ProjectCreateDraft(
        name: 'My Project',
        type: ProjectType.team,
        inviteEmails: ['not-an-email'],
      ).validate();
      expect(v.inviteError, isNotNull);
    });

    test('passes with valid inputs', () {
      final v = ProjectCreateDraft(
        name: 'My Project',
        type: ProjectType.team,
        deadline: DateTime.now().add(const Duration(days: 7)),
        inviteEmails: const ['alice@example.com'],
      ).validate();
      expect(v.isValid, isTrue);
    });
  });

  group('ProjectCreateDraft.toCreatePayload', () {
    test('includes deadline as ISO string when set', () {
      final draft = ProjectCreateDraft(
        name: 'My Project',
        type: ProjectType.team,
        deadline: DateTime(2026, 7, 1),
      );
      final payload = draft.toCreatePayload();
      expect(payload['name'], 'My Project');
      expect(payload['type'], 'Team');
      expect(payload['deadline'], isA<String>());
    });

    test('omits deadline when null', () {
      final payload = const ProjectCreateDraft(name: 'X').toCreatePayload();
      expect(payload.containsKey('deadline'), isFalse);
    });
  });

  group('ProjectCreateDraft.hasInvitations', () {
    test('false for personal (non-collaborative) projects', () {
      const draft = ProjectCreateDraft(
        name: 'My Project',
        inviteEmails: ['alice@example.com'],
      );
      expect(draft.hasInvitations, isFalse);
    });

    test('true when collaborative type has invites queued', () {
      const draft = ProjectCreateDraft(
        name: 'My Project',
        type: ProjectType.team,
        inviteEmails: ['alice@example.com'],
      );
      expect(draft.hasInvitations, isTrue);
    });
  });
}
