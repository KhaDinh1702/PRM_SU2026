import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm_app/features/tasks/models/task_tag.dart';

void main() {
  group('TaskTag', () {
    test('round-trips through JSON', () {
      const original =
          TaskTag(id: 't1', name: 'urgent', colorValue: 0xFFEF4444);
      final restored = TaskTag.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.colorValue, original.colorValue);
    });

    test('color getter returns a Flutter Color', () {
      const tag = TaskTag(id: 't', name: 'x', colorValue: 0xFF06B6D4);
      expect(tag.color, isA<Color>());
      expect(tag.color.toARGB32(), 0xFF06B6D4);
    });

    test('copyWith replaces name without touching color', () {
      const original =
          TaskTag(id: 't', name: 'old', colorValue: 0xFF06B6D4);
      final updated = original.copyWith(name: 'new');
      expect(updated.name, 'new');
      expect(updated.colorValue, original.colorValue);
    });

    test('parsing handles missing color with sensible default', () {
      final tag = TaskTag.fromJson({'id': 'x', 'name': 'foo'});
      expect(tag.colorValue, 0xFF06B6D4);
    });

    test('palette has 8 colors', () {
      expect(TaskTag.paletteColors.length, 8);
    });
  });
}
