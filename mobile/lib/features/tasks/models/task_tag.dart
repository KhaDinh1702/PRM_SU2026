import 'package:flutter/material.dart';

/// User-defined label that can be attached to tasks (cross-cutting, unlike
/// project which is "where" — a tag is "what kind").
class TaskTag {
  final String id;
  final String name;
  final int colorValue;

  const TaskTag({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  Color get color => Color(colorValue);

  TaskTag copyWith({String? id, String? name, int? colorValue}) {
    return TaskTag(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': colorValue,
      };

  factory TaskTag.fromJson(Map<String, dynamic> json) {
    return TaskTag(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      colorValue: _parseInt(json['color']) ?? 0xFF06B6D4,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  /// Palette offered when creating a new tag.
  static const List<int> paletteColors = [
    0xFF06B6D4, // cyan
    0xFFEF4444, // red
    0xFFF59E0B, // amber
    0xFF10B981, // green
    0xFF8B5CF6, // purple
    0xFFEC4899, // pink
    0xFF3B82F6, // blue
    0xFF64748B, // slate
  ];
}
