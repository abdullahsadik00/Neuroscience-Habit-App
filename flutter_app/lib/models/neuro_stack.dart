enum HabitCategory { focus, wellness, mindset, fitness }

class NeuroStack {
  final String id;
  final String title;
  final String anchorCue;
  final String action;
  final String reward;
  final HabitCategory category;
  final int acetylcholineDuration;
  final double myelinationLevel;
  final int streak;
  final List<String> completions;
  final String createdAt;
  final bool isActive;

  const NeuroStack({
    required this.id,
    required this.title,
    required this.anchorCue,
    required this.action,
    required this.reward,
    required this.category,
    required this.acetylcholineDuration,
    required this.myelinationLevel,
    required this.streak,
    required this.completions,
    required this.createdAt,
    required this.isActive,
  });

  NeuroStack copyWith({
    String? id,
    String? title,
    String? anchorCue,
    String? action,
    String? reward,
    HabitCategory? category,
    int? acetylcholineDuration,
    double? myelinationLevel,
    int? streak,
    List<String>? completions,
    String? createdAt,
    bool? isActive,
  }) =>
      NeuroStack(
        id: id ?? this.id,
        title: title ?? this.title,
        anchorCue: anchorCue ?? this.anchorCue,
        action: action ?? this.action,
        reward: reward ?? this.reward,
        category: category ?? this.category,
        acetylcholineDuration: acetylcholineDuration ?? this.acetylcholineDuration,
        myelinationLevel: myelinationLevel ?? this.myelinationLevel,
        streak: streak ?? this.streak,
        completions: completions ?? this.completions,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'anchorCue': anchorCue,
        'action': action,
        'reward': reward,
        'category': category.name,
        'acetylcholineDuration': acetylcholineDuration,
        'myelinationLevel': myelinationLevel,
        'streak': streak,
        'completions': completions,
        'createdAt': createdAt,
        'isActive': isActive,
      };

  factory NeuroStack.fromJson(Map<String, dynamic> json) => NeuroStack(
        id: json['id'] as String,
        title: json['title'] as String,
        anchorCue: json['anchorCue'] as String,
        action: json['action'] as String,
        reward: json['reward'] as String,
        category: HabitCategory.values.firstWhere(
          (c) => c.name == json['category'],
          orElse: () => HabitCategory.focus,
        ),
        acetylcholineDuration: json['acetylcholineDuration'] as int,
        myelinationLevel: (json['myelinationLevel'] as num).toDouble(),
        streak: json['streak'] as int,
        completions: List<String>.from(json['completions'] as List),
        createdAt: json['createdAt'] as String,
        isActive: json['isActive'] as bool,
      );
}
