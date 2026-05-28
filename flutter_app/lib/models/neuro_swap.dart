class NeuroSwap {
  final String id;
  final String title;
  final String cue;
  final String badResponse;
  final String interceptAction;
  final int frictionLevel;
  final List<String> frictionSteps;
  final List<String> urgeSurfingCompletions;
  final List<String> slips;
  final String createdAt;
  final bool isActive;

  const NeuroSwap({
    required this.id,
    required this.title,
    required this.cue,
    required this.badResponse,
    required this.interceptAction,
    required this.frictionLevel,
    required this.frictionSteps,
    required this.urgeSurfingCompletions,
    required this.slips,
    required this.createdAt,
    required this.isActive,
  });

  NeuroSwap copyWith({
    String? id,
    String? title,
    String? cue,
    String? badResponse,
    String? interceptAction,
    int? frictionLevel,
    List<String>? frictionSteps,
    List<String>? urgeSurfingCompletions,
    List<String>? slips,
    String? createdAt,
    bool? isActive,
  }) =>
      NeuroSwap(
        id: id ?? this.id,
        title: title ?? this.title,
        cue: cue ?? this.cue,
        badResponse: badResponse ?? this.badResponse,
        interceptAction: interceptAction ?? this.interceptAction,
        frictionLevel: frictionLevel ?? this.frictionLevel,
        frictionSteps: frictionSteps ?? this.frictionSteps,
        urgeSurfingCompletions: urgeSurfingCompletions ?? this.urgeSurfingCompletions,
        slips: slips ?? this.slips,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'cue': cue,
        'badResponse': badResponse,
        'interceptAction': interceptAction,
        'frictionLevel': frictionLevel,
        'frictionSteps': frictionSteps,
        'urgeSurfingCompletions': urgeSurfingCompletions,
        'slips': slips,
        'createdAt': createdAt,
        'isActive': isActive,
      };

  factory NeuroSwap.fromJson(Map<String, dynamic> json) => NeuroSwap(
        id: json['id'] as String,
        title: json['title'] as String,
        cue: json['cue'] as String,
        badResponse: json['badResponse'] as String,
        interceptAction: json['interceptAction'] as String,
        frictionLevel: json['frictionLevel'] as int,
        frictionSteps: List<String>.from(json['frictionSteps'] as List),
        urgeSurfingCompletions: List<String>.from(json['urgeSurfingCompletions'] as List),
        slips: List<String>.from(json['slips'] as List),
        createdAt: json['createdAt'] as String,
        isActive: json['isActive'] as bool,
      );
}
