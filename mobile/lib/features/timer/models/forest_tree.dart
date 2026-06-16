class ForestTree {
  final DateTime timestamp;
  final String mode;
  final int durationSeconds;
  final bool isSuccess;

  const ForestTree({
    required this.timestamp,
    required this.mode,
    required this.durationSeconds,
    required this.isSuccess,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'mode': mode,
        'durationSeconds': durationSeconds,
        'isSuccess': isSuccess,
      };

  factory ForestTree.fromJson(Map<String, dynamic> json) {
    return ForestTree(
      timestamp: DateTime.parse(json['timestamp'] as String),
      mode: json['mode'] as String,
      durationSeconds: json['durationSeconds'] as int,
      isSuccess: json['isSuccess'] as bool,
    );
  }
}
