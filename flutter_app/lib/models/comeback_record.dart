class ComebackRecord {
  final String id;
  final String stackId;
  final String date;
  final bool microActionsCompleted;
  final String completedAt;

  const ComebackRecord({
    required this.id,
    required this.stackId,
    required this.date,
    required this.microActionsCompleted,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'stackId': stackId,
        'date': date,
        'microActionsCompleted': microActionsCompleted,
        'completedAt': completedAt,
      };

  factory ComebackRecord.fromJson(Map<String, dynamic> json) => ComebackRecord(
        id: json['id'] as String,
        stackId: json['stackId'] as String,
        date: json['date'] as String,
        microActionsCompleted: json['microActionsCompleted'] as bool,
        completedAt: json['completedAt'] as String,
      );
}
