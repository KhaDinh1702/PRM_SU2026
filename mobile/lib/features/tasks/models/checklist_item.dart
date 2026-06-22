/// Single sub-task / checklist item that belongs to a parent [TaskModel].
///
/// Persisted locally (per `(userId, taskId)`) via `ChecklistService`.
/// Backend support is out of scope for now — keeping this client-side lets
/// the rest of the engine and UI ship without a server change.
class ChecklistItem {
  final String id;
  final String text;
  final bool isDone;

  const ChecklistItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  ChecklistItem copyWith({String? id, String? text, bool? isDone}) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isDone': isDone,
      };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      isDone: json['isDone'] == true,
    );
  }
}

/// Compact progress summary used by the parent task card.
class ChecklistProgress {
  final int done;
  final int total;

  const ChecklistProgress({required this.done, required this.total});

  static const ChecklistProgress empty = ChecklistProgress(done: 0, total: 0);

  bool get hasItems => total > 0;
  bool get isComplete => total > 0 && done == total;
  double get ratio => total == 0 ? 0 : done / total;
  String get label => '$done/$total';
}
