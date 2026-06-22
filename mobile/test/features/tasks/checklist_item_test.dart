import 'package:flutter_test/flutter_test.dart';
import 'package:prm_app/features/tasks/models/checklist_item.dart';

void main() {
  group('ChecklistItem', () {
    test('round-trips through JSON', () {
      const original = ChecklistItem(id: 'c1', text: 'Step 1', isDone: true);
      final restored = ChecklistItem.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.text, original.text);
      expect(restored.isDone, original.isDone);
    });

    test('defaults isDone to false', () {
      final item = ChecklistItem.fromJson({'id': 'x', 'text': 'do thing'});
      expect(item.isDone, isFalse);
    });

    test('copyWith toggles isDone without touching other fields', () {
      const item = ChecklistItem(id: 'c1', text: 'Step');
      final toggled = item.copyWith(isDone: true);
      expect(toggled.isDone, isTrue);
      expect(toggled.text, item.text);
      expect(toggled.id, item.id);
    });
  });

  group('ChecklistProgress', () {
    test('empty progress has no items and 0% ratio', () {
      const p = ChecklistProgress.empty;
      expect(p.hasItems, isFalse);
      expect(p.ratio, 0);
      expect(p.isComplete, isFalse);
    });

    test('isComplete when done == total > 0', () {
      const p = ChecklistProgress(done: 3, total: 3);
      expect(p.isComplete, isTrue);
      expect(p.ratio, 1.0);
    });

    test('label formats as "done/total"', () {
      const p = ChecklistProgress(done: 2, total: 5);
      expect(p.label, '2/5');
    });

    test('ratio is computed precisely for partial progress', () {
      const p = ChecklistProgress(done: 1, total: 4);
      expect(p.ratio, 0.25);
    });
  });
}
