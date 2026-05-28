enum SuggestionType { scaleDown, replace, updateMicro }

class RecalibrationSuggestion {
  final String id;
  final SuggestionType type;
  final String? habitId;
  final String? habitTitle;
  final String reason;
  final String fromValue;
  final String toValue;
  final String? replacementTemplateId;

  const RecalibrationSuggestion({
    required this.id,
    required this.type,
    this.habitId,
    this.habitTitle,
    required this.reason,
    required this.fromValue,
    required this.toValue,
    this.replacementTemplateId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'habitId': habitId,
        'habitTitle': habitTitle,
        'reason': reason,
        'fromValue': fromValue,
        'toValue': toValue,
        'replacementTemplateId': replacementTemplateId,
      };

  factory RecalibrationSuggestion.fromJson(Map<String, dynamic> json) =>
      RecalibrationSuggestion(
        id: json['id'] as String,
        type: SuggestionType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => SuggestionType.scaleDown,
        ),
        habitId: json['habitId'] as String?,
        habitTitle: json['habitTitle'] as String?,
        reason: json['reason'] as String,
        fromValue: json['fromValue'] as String,
        toValue: json['toValue'] as String,
        replacementTemplateId: json['replacementTemplateId'] as String?,
      );
}

class RecalibrationEvent {
  final String id;
  final String date;
  final List<RecalibrationSuggestion> suggestions;
  final List<String> accepted;
  final List<String> rejected;

  const RecalibrationEvent({
    required this.id,
    required this.date,
    required this.suggestions,
    required this.accepted,
    required this.rejected,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'suggestions': suggestions.map((s) => s.toJson()).toList(),
        'accepted': accepted,
        'rejected': rejected,
      };

  factory RecalibrationEvent.fromJson(Map<String, dynamic> json) =>
      RecalibrationEvent(
        id: json['id'] as String,
        date: json['date'] as String,
        suggestions: (json['suggestions'] as List)
            .map((s) => RecalibrationSuggestion.fromJson(s as Map<String, dynamic>))
            .toList(),
        accepted: List<String>.from(json['accepted'] as List),
        rejected: List<String>.from(json['rejected'] as List),
      );
}
