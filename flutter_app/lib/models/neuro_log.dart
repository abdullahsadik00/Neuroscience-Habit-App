enum LogType { completion, urgeSurf, slip, comeback }

class NeuroLog {
  final String id;
  final String timestamp;
  final LogType type;
  final String itemId;
  final String itemTitle;
  final String? notes;
  final int dopamineChange;
  final int epinephrineChange;
  final int gabaChange;
  final int acetylcholineChange;

  const NeuroLog({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.itemId,
    required this.itemTitle,
    this.notes,
    required this.dopamineChange,
    required this.epinephrineChange,
    required this.gabaChange,
    required this.acetylcholineChange,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp,
        'type': type.name,
        'itemId': itemId,
        'itemTitle': itemTitle,
        'notes': notes,
        'dopamineChange': dopamineChange,
        'epinephrineChange': epinephrineChange,
        'gabaChange': gabaChange,
        'acetylcholineChange': acetylcholineChange,
      };

  factory NeuroLog.fromJson(Map<String, dynamic> json) => NeuroLog(
        id: json['id'] as String,
        timestamp: json['timestamp'] as String,
        type: LogType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => LogType.completion,
        ),
        itemId: json['itemId'] as String,
        itemTitle: json['itemTitle'] as String,
        notes: json['notes'] as String?,
        dopamineChange: json['dopamineChange'] as int,
        epinephrineChange: json['epinephrineChange'] as int,
        gabaChange: json['gabaChange'] as int,
        acetylcholineChange: json['acetylcholineChange'] as int,
      );
}
