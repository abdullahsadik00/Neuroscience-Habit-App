import 'brain_profile.dart';

enum EnergyLevel { low, normal, high }

class CheckinRecord {
  final String id;
  final String date;
  final int consistency; // 1-5
  final String weeklyBlocker;
  final EnergyLevel energyLevel;
  final bool routineChanged;
  final String? routineNote;
  final bool? contextChanged;
  final FailureStyle? currentFailureMode;
  final bool recalibrationApplied;

  const CheckinRecord({
    required this.id,
    required this.date,
    required this.consistency,
    required this.weeklyBlocker,
    required this.energyLevel,
    required this.routineChanged,
    this.routineNote,
    this.contextChanged,
    this.currentFailureMode,
    required this.recalibrationApplied,
  });

  CheckinRecord copyWith({bool? recalibrationApplied}) => CheckinRecord(
        id: id,
        date: date,
        consistency: consistency,
        weeklyBlocker: weeklyBlocker,
        energyLevel: energyLevel,
        routineChanged: routineChanged,
        routineNote: routineNote,
        contextChanged: contextChanged,
        currentFailureMode: currentFailureMode,
        recalibrationApplied: recalibrationApplied ?? this.recalibrationApplied,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'consistency': consistency,
        'weeklyBlocker': weeklyBlocker,
        'energyLevel': energyLevel.name,
        'routineChanged': routineChanged,
        'routineNote': routineNote,
        'contextChanged': contextChanged,
        'currentFailureMode': currentFailureMode?.name,
        'recalibrationApplied': recalibrationApplied,
      };

  factory CheckinRecord.fromJson(Map<String, dynamic> json) => CheckinRecord(
        id: json['id'] as String,
        date: json['date'] as String,
        consistency: json['consistency'] as int,
        weeklyBlocker: json['weeklyBlocker'] as String,
        energyLevel: EnergyLevel.values.firstWhere(
          (e) => e.name == json['energyLevel'],
          orElse: () => EnergyLevel.normal,
        ),
        routineChanged: json['routineChanged'] as bool,
        routineNote: json['routineNote'] as String?,
        contextChanged: json['contextChanged'] as bool?,
        currentFailureMode: json['currentFailureMode'] != null
            ? FailureStyle.values.firstWhere(
                (f) => f.name == json['currentFailureMode'],
                orElse: () => FailureStyle.drifter,
              )
            : null,
        recalibrationApplied: json['recalibrationApplied'] as bool,
      );
}
