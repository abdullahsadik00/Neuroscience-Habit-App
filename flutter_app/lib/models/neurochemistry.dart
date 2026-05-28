class Neurochemistry {
  final double dopamine;
  final double acetylcholine;
  final double epinephrine;
  final double gaba;

  const Neurochemistry({
    required this.dopamine,
    required this.acetylcholine,
    required this.epinephrine,
    required this.gaba,
  });

  static const Neurochemistry initial = Neurochemistry(
    dopamine: 65,
    acetylcholine: 55,
    epinephrine: 50,
    gaba: 60,
  );

  static const Neurochemistry baseline = Neurochemistry(
    dopamine: 50,
    acetylcholine: 50,
    epinephrine: 50,
    gaba: 50,
  );

  Neurochemistry copyWith({
    double? dopamine,
    double? acetylcholine,
    double? epinephrine,
    double? gaba,
  }) =>
      Neurochemistry(
        dopamine: dopamine ?? this.dopamine,
        acetylcholine: acetylcholine ?? this.acetylcholine,
        epinephrine: epinephrine ?? this.epinephrine,
        gaba: gaba ?? this.gaba,
      );

  Map<String, dynamic> toJson() => {
        'dopamine': dopamine,
        'acetylcholine': acetylcholine,
        'epinephrine': epinephrine,
        'gaba': gaba,
      };

  factory Neurochemistry.fromJson(Map<String, dynamic> json) => Neurochemistry(
        dopamine: (json['dopamine'] as num).toDouble(),
        acetylcholine: (json['acetylcholine'] as num).toDouble(),
        epinephrine: (json['epinephrine'] as num).toDouble(),
        gaba: (json['gaba'] as num).toDouble(),
      );
}
