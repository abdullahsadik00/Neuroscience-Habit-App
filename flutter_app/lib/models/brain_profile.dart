enum FailureStyle { perfectionist, avoider, analyst, drifter }

enum PeakEnergyWindow { morning, afternoon, evening, variable }

enum RecoverySpeed { fast, medium, slow, variable }

enum PrimaryBlocker { energy, overwhelm, distraction, life }

enum SelfTalkPattern { selfCritical, avoidant, rational, hopeless }

enum MotivationSource { identity, outcome, process, survival }

enum AccountabilityStyle { tracking, external, systems, none }

enum CoreDriver { feelBetter, performBetter, becomeSomeone, survive }

class NeuroBrainProfile {
  final FailureStyle failureStyle;
  final PeakEnergyWindow peakEnergyWindow;
  final RecoverySpeed recoverySpeed;
  final PrimaryBlocker primaryBlocker;
  final SelfTalkPattern selfTalkPattern;
  final MotivationSource motivationSource;
  final AccountabilityStyle accountabilityStyle;
  final CoreDriver coreDriver;
  final String completedAt;

  const NeuroBrainProfile({
    required this.failureStyle,
    required this.peakEnergyWindow,
    required this.recoverySpeed,
    required this.primaryBlocker,
    required this.selfTalkPattern,
    required this.motivationSource,
    required this.accountabilityStyle,
    required this.coreDriver,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'failureStyle': failureStyle.name,
        'peakEnergyWindow': peakEnergyWindow.name,
        'recoverySpeed': recoverySpeed.name,
        'primaryBlocker': primaryBlocker.name,
        'selfTalkPattern': selfTalkPattern.name,
        'motivationSource': motivationSource.name,
        'accountabilityStyle': accountabilityStyle.name,
        'coreDriver': coreDriver.name,
        'completedAt': completedAt,
      };

  factory NeuroBrainProfile.fromJson(Map<String, dynamic> json) {
    T pick<T>(List<T> values, String name, T fallback) {
      try {
        return (values as List<dynamic>).firstWhere(
          (v) => (v as dynamic).name == name,
          orElse: () => fallback,
        ) as T;
      } catch (_) {
        return fallback;
      }
    }

    return NeuroBrainProfile(
      failureStyle: pick(FailureStyle.values, json['failureStyle'] as String, FailureStyle.drifter),
      peakEnergyWindow: pick(PeakEnergyWindow.values, json['peakEnergyWindow'] as String, PeakEnergyWindow.morning),
      recoverySpeed: pick(RecoverySpeed.values, json['recoverySpeed'] as String, RecoverySpeed.medium),
      primaryBlocker: pick(PrimaryBlocker.values, json['primaryBlocker'] as String, PrimaryBlocker.distraction),
      selfTalkPattern: pick(SelfTalkPattern.values, json['selfTalkPattern'] as String, SelfTalkPattern.rational),
      motivationSource: pick(MotivationSource.values, json['motivationSource'] as String, MotivationSource.outcome),
      accountabilityStyle: pick(AccountabilityStyle.values, json['accountabilityStyle'] as String, AccountabilityStyle.tracking),
      coreDriver: pick(CoreDriver.values, json['coreDriver'] as String, CoreDriver.performBetter),
      completedAt: json['completedAt'] as String,
    );
  }
}
