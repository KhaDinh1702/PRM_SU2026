import 'package:flutter_test/flutter_test.dart';
import 'package:prm_app/features/tasks/models/recurrence_rule.dart';

void main() {
  group('RecurrenceRule.nextOccurrence — daily', () {
    test('every day adds 1 day', () {
      const rule = RecurrenceRule(pattern: RecurrencePattern.daily);
      final next = rule.nextOccurrence(DateTime(2026, 6, 20));
      expect(next, DateTime(2026, 6, 21));
    });

    test('every 3 days adds 3 days', () {
      const rule = RecurrenceRule(
        pattern: RecurrencePattern.daily,
        interval: 3,
      );
      final next = rule.nextOccurrence(DateTime(2026, 6, 20));
      expect(next, DateTime(2026, 6, 23));
    });

    test('returns null past endDate', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.daily,
        endDate: DateTime(2026, 6, 20),
      );
      // Asking after the end date — next occurrence would be Jun 22,
      // which is beyond the rule's endDate (Jun 20).
      final next = rule.nextOccurrence(DateTime(2026, 6, 21));
      expect(next, isNull);
    });
  });

  group('RecurrenceRule.nextOccurrence — weekly', () {
    test('without weekdays, jumps 1 week ahead', () {
      const rule = RecurrenceRule(pattern: RecurrencePattern.weekly);
      final next = rule.nextOccurrence(DateTime(2026, 6, 20));
      expect(next, DateTime(2026, 6, 27));
    });

    test('with Mon/Wed/Fri, finds the next listed day', () {
      // 2026-06-20 is a Saturday → next Mon should be 2026-06-22.
      const rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        weekdays: {1, 3, 5}, // Mon, Wed, Fri
      );
      final next = rule.nextOccurrence(DateTime(2026, 6, 20));
      expect(next?.weekday, 1);
      expect(next, DateTime(2026, 6, 22));
    });

    test('from Wed picks up Fri when both are listed', () {
      // 2026-06-24 is a Wednesday.
      const rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        weekdays: {3, 5},
      );
      final next = rule.nextOccurrence(DateTime(2026, 6, 24));
      expect(next?.weekday, 5);
      expect(next, DateTime(2026, 6, 26));
    });
  });

  group('RecurrenceRule.nextOccurrence — monthly', () {
    test('every month bumps to the same day next month', () {
      const rule = RecurrenceRule(pattern: RecurrencePattern.monthly);
      final next = rule.nextOccurrence(DateTime(2026, 6, 20));
      expect(next, DateTime(2026, 7, 20));
    });

    test('clamps day to month end when target month is shorter', () {
      // Jan 31 → Feb 28 (2026 is not a leap year)
      const rule = RecurrenceRule(pattern: RecurrencePattern.monthly);
      final next = rule.nextOccurrence(DateTime(2026, 1, 31));
      expect(next, DateTime(2026, 2, 28));
    });

    test('every 2 months', () {
      const rule = RecurrenceRule(
        pattern: RecurrencePattern.monthly,
        interval: 2,
      );
      final next = rule.nextOccurrence(DateTime(2026, 1, 15));
      expect(next, DateTime(2026, 3, 15));
    });
  });

  group('RecurrenceRule serialization', () {
    test('round-trips through JSON', () {
      final rule = RecurrenceRule(
        pattern: RecurrencePattern.weekly,
        interval: 2,
        weekdays: const {1, 3, 5},
        endDate: DateTime(2026, 12, 31),
      );
      final restored = RecurrenceRule.fromJson(rule.toJson());
      expect(restored.pattern, rule.pattern);
      expect(restored.interval, rule.interval);
      expect(restored.weekdays, rule.weekdays);
      expect(restored.endDate, rule.endDate);
    });

    test('defaults gracefully on missing fields', () {
      final rule = RecurrenceRule.fromJson({});
      expect(rule.pattern, RecurrencePattern.daily);
      expect(rule.interval, 1);
      expect(rule.weekdays, isEmpty);
      expect(rule.endDate, isNull);
    });
  });

  group('RecurrenceRule.describe', () {
    test('describes daily', () {
      expect(
        const RecurrenceRule(pattern: RecurrencePattern.daily).describe(),
        'Every day',
      );
      expect(
        const RecurrenceRule(
          pattern: RecurrencePattern.daily,
          interval: 3,
        ).describe(),
        'Every 3 days',
      );
    });

    test('describes weekly with selected weekdays', () {
      expect(
        const RecurrenceRule(
          pattern: RecurrencePattern.weekly,
          weekdays: {1, 3, 5},
        ).describe(),
        'Mon, Wed, Fri',
      );
    });
  });
}
