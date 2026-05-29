import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/neuro_helpers.dart';
import '../data/habit_library.dart';

const _storageKey = 'neuroflow-state-v1';
const _uuid = Uuid();
const _milestones = [10, 25, 50, 75, 100];

// Provided via ProviderScope override at startup
final initialStateProvider = Provider<NeuroState>((_) => NeuroState.initial());
final sharedPreferencesProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());

// Theme provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

// Emits (habitTitle, milestonePercent) when myelination crosses a milestone.
// Dashboard watches this and shows celebration, then sets it back to null.
final milestoneEventProvider = StateProvider<(String, int)?>((_) => null);

// Emits an upgrade-gate message when a free-tier limit is hit.
final proGateEventProvider = StateProvider<String?>((_) => null);

@immutable
class NeuroState {
  final List<NeuroStack> stacks;
  final List<NeuroSwap> swaps;
  final List<NeuroLog> logs;
  final List<ComebackRecord> comebacks;
  final Neurochemistry neurochemistry;
  final int dopaminePoints;
  final UserProfile userProfile;
  final bool isPro;
  final bool onboardingComplete;
  final NeuroBrainProfile? brainProfile;
  final bool blueprintAccepted;
  final String? lastCheckinDate;
  final List<CheckinRecord> checkinHistory;
  final List<RecalibrationEvent> recalibrationLog;

  const NeuroState({
    required this.stacks,
    required this.swaps,
    required this.logs,
    required this.comebacks,
    required this.neurochemistry,
    required this.dopaminePoints,
    required this.userProfile,
    required this.isPro,
    required this.onboardingComplete,
    this.brainProfile,
    required this.blueprintAccepted,
    this.lastCheckinDate,
    required this.checkinHistory,
    required this.recalibrationLog,
  });

  factory NeuroState.initial() => const NeuroState(
        stacks: [],
        swaps: [],
        logs: [],
        comebacks: [],
        neurochemistry: Neurochemistry.initial,
        dopaminePoints: 0,
        userProfile: UserProfile.empty,
        isPro: false,
        onboardingComplete: false,
        brainProfile: null,
        blueprintAccepted: false,
        lastCheckinDate: null,
        checkinHistory: [],
        recalibrationLog: [],
      );

  NeuroState copyWith({
    List<NeuroStack>? stacks,
    List<NeuroSwap>? swaps,
    List<NeuroLog>? logs,
    List<ComebackRecord>? comebacks,
    Neurochemistry? neurochemistry,
    int? dopaminePoints,
    UserProfile? userProfile,
    bool? isPro,
    bool? onboardingComplete,
    NeuroBrainProfile? brainProfile,
    bool? blueprintAccepted,
    String? lastCheckinDate,
    List<CheckinRecord>? checkinHistory,
    List<RecalibrationEvent>? recalibrationLog,
  }) =>
      NeuroState(
        stacks: stacks ?? this.stacks,
        swaps: swaps ?? this.swaps,
        logs: logs ?? this.logs,
        comebacks: comebacks ?? this.comebacks,
        neurochemistry: neurochemistry ?? this.neurochemistry,
        dopaminePoints: dopaminePoints ?? this.dopaminePoints,
        userProfile: userProfile ?? this.userProfile,
        isPro: isPro ?? this.isPro,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        brainProfile: brainProfile ?? this.brainProfile,
        blueprintAccepted: blueprintAccepted ?? this.blueprintAccepted,
        lastCheckinDate: lastCheckinDate ?? this.lastCheckinDate,
        checkinHistory: checkinHistory ?? this.checkinHistory,
        recalibrationLog: recalibrationLog ?? this.recalibrationLog,
      );

  Map<String, dynamic> toJson() => {
        'stacks': stacks.map((s) => s.toJson()).toList(),
        'swaps': swaps.map((s) => s.toJson()).toList(),
        'logs': logs.map((l) => l.toJson()).toList(),
        'comebacks': comebacks.map((c) => c.toJson()).toList(),
        'neurochemistry': neurochemistry.toJson(),
        'dopaminePoints': dopaminePoints,
        'userProfile': userProfile.toJson(),
        'isPro': isPro,
        'onboardingComplete': onboardingComplete,
        'brainProfile': brainProfile?.toJson(),
        'blueprintAccepted': blueprintAccepted,
        'lastCheckinDate': lastCheckinDate,
        'checkinHistory': checkinHistory.map((c) => c.toJson()).toList(),
        'recalibrationLog': recalibrationLog.map((r) => r.toJson()).toList(),
      };

  factory NeuroState.fromJson(Map<String, dynamic> json) {
    try {
      return NeuroState(
        stacks: (json['stacks'] as List? ?? [])
            .map((s) => NeuroStack.fromJson(s as Map<String, dynamic>))
            .toList(),
        swaps: (json['swaps'] as List? ?? [])
            .map((s) => NeuroSwap.fromJson(s as Map<String, dynamic>))
            .toList(),
        logs: (json['logs'] as List? ?? [])
            .map((l) => NeuroLog.fromJson(l as Map<String, dynamic>))
            .toList(),
        comebacks: (json['comebacks'] as List? ?? [])
            .map((c) => ComebackRecord.fromJson(c as Map<String, dynamic>))
            .toList(),
        neurochemistry: json['neurochemistry'] != null
            ? Neurochemistry.fromJson(json['neurochemistry'] as Map<String, dynamic>)
            : Neurochemistry.initial,
        dopaminePoints: json['dopaminePoints'] as int? ?? 0,
        userProfile: json['userProfile'] != null
            ? UserProfile.fromJson(json['userProfile'] as Map<String, dynamic>)
            : UserProfile.empty,
        isPro: json['isPro'] as bool? ?? false,
        onboardingComplete: json['onboardingComplete'] as bool? ?? false,
        brainProfile: json['brainProfile'] != null
            ? NeuroBrainProfile.fromJson(json['brainProfile'] as Map<String, dynamic>)
            : null,
        blueprintAccepted: json['blueprintAccepted'] as bool? ?? false,
        lastCheckinDate: json['lastCheckinDate'] as String?,
        checkinHistory: (json['checkinHistory'] as List? ?? [])
            .map((c) => CheckinRecord.fromJson(c as Map<String, dynamic>))
            .toList(),
        recalibrationLog: (json['recalibrationLog'] as List? ?? [])
            .map((r) => RecalibrationEvent.fromJson(r as Map<String, dynamic>))
            .toList(),
      );
    } catch (_) {
      return NeuroState.initial();
    }
  }
}

class NeuroNotifier extends Notifier<NeuroState> {
  late final SharedPreferences _prefs;

  @override
  NeuroState build() {
    _prefs = ref.read(sharedPreferencesProvider);
    return ref.read(initialStateProvider);
  }

  void _save(NeuroState newState) {
    state = newState;
    _prefs.setString(_storageKey, jsonEncode(newState.toJson()));
    _syncToCloud(newState);
  }

  // Upserts the full state JSON to Supabase. Fire-and-forget — local state is
  // already updated synchronously; cloud failure is non-blocking.
  Future<void> _syncToCloud(NeuroState newState) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;
      await client.from('neuro_state').upsert({
        'user_id': user.id,
        'state_json': newState.toJson(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Sync failure is silent — the local copy is the source of truth.
    }
  }

  // Called on sign-in: pulls the cloud row and hydrates local state.
  Future<void> loadFromCloud() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;
      final row = await client
          .from('neuro_state')
          .select('state_json')
          .eq('user_id', user.id)
          .maybeSingle();
      if (row != null && row['state_json'] != null) {
        final loaded = NeuroState.fromJson(row['state_json'] as Map<String, dynamic>);
        _prefs.setString(_storageKey, jsonEncode(loaded.toJson()));
        state = loaded;
      }
    } catch (_) {
      // If cloud load fails, keep the local state as-is.
    }
  }

  // ── STACKS ────────────────────────────────────────────────────────────────

  bool get canAddStack =>
      state.isPro || state.stacks.where((s) => s.isActive).length < 5;

  void addNeuroStack({
    required String title,
    required String anchorCue,
    required String action,
    required String reward,
    required HabitCategory category,
    required int acetylcholineDuration,
    String? whenCondition,
    String? thenAction,
  }) {
    if (!canAddStack) {
      ref.read(proGateEventProvider.notifier).state =
          'Free plan supports up to 5 active habits. Upgrade to Pro for unlimited habits, failure signatures, and deeper recovery insights.';
      return;
    }
    final stack = NeuroStack(
      id: 'stack-${_uuid.v4()}',
      title: title,
      anchorCue: anchorCue,
      action: action,
      reward: reward,
      category: category,
      acetylcholineDuration: acetylcholineDuration,
      myelinationLevel: 0,
      streak: 0,
      completions: const [],
      createdAt: DateTime.now().toIso8601String(),
      isActive: true,
      whenCondition: whenCondition,
      thenAction: thenAction,
    );
    _save(state.copyWith(stacks: [stack, ...state.stacks]));
  }

  void updateNeuroStack(String id, NeuroStack Function(NeuroStack) update) {
    _save(state.copyWith(
      stacks: state.stacks.map((s) => s.id == id ? update(s) : s).toList(),
    ));
  }

  // Soft-delete: sets isActive=false. Hard deletes are only for data reset.
  void archiveNeuroStack(String id) {
    _save(state.copyWith(
      stacks: state.stacks.map((s) => s.id == id ? s.copyWith(isActive: false) : s).toList(),
    ));
  }

  void unarchiveNeuroStack(String id) {
    _save(state.copyWith(
      stacks: state.stacks.map((s) => s.id == id ? s.copyWith(isActive: true) : s).toList(),
    ));
  }

  void completeNeuroStack(String id, {String? notes}) {
    final todayStr = getLocalDateString(DateTime.now());
    int dopamineAward = 25;
    int acetylcholineAward = 20;
    String? celebratedTitle;
    int? milestoneHit;

    final updatedStacks = state.stacks.map((stack) {
      if (stack.id != id) return stack;
      final alreadyDone = stack.completions.contains(todayStr);
      final completions = alreadyDone ? stack.completions : [...stack.completions, todayStr];
      final streak = calculateStreak(completions);
      final oldMyelination = stack.myelinationLevel;
      final newMyelination = calculateMyelination(completions.length, streak);
      if (streak > 5) {
        dopamineAward = 40;
        acetylcholineAward = 30;
      }
      // Check milestone crossing (10/25/50/75/100)
      for (final m in _milestones) {
        if (oldMyelination < m && newMyelination >= m) {
          celebratedTitle = stack.title;
          milestoneHit = m;
          break;
        }
      }
      return stack.copyWith(completions: completions, streak: streak, myelinationLevel: newMyelination);
    }).toList();

    if (celebratedTitle != null && milestoneHit != null) {
      ref.read(milestoneEventProvider.notifier).state = (celebratedTitle!, milestoneHit!);
    }

    final completed = state.stacks.firstWhere((s) => s.id == id, orElse: () => state.stacks.first);
    final log = NeuroLog(
      id: 'log-${_uuid.v4()}',
      timestamp: DateTime.now().toIso8601String(),
      type: LogType.completion,
      itemId: id,
      itemTitle: completed.title,
      notes: notes,
      dopamineChange: dopamineAward,
      epinephrineChange: 5,
      gabaChange: 0,
      acetylcholineChange: acetylcholineAward,
    );

    final chem = state.neurochemistry;
    _save(state.copyWith(
      stacks: updatedStacks,
      logs: [log, ...state.logs],
      dopaminePoints: state.dopaminePoints + dopamineAward,
      neurochemistry: chem.copyWith(
        dopamine: (chem.dopamine + dopamineAward).clamp(0, 100),
        acetylcholine: (chem.acetylcholine + acetylcholineAward).clamp(0, 100),
        epinephrine: (chem.epinephrine + 5).clamp(0, 100),
      ),
    ));
  }

  // ── SWAPS ────────────────────────────────────────────────────────────────

  bool get canAddSwap =>
      state.isPro || state.swaps.where((s) => s.isActive).length < 3;

  void addNeuroSwap({
    required String title,
    required String cue,
    required String badResponse,
    required String interceptAction,
    required int frictionLevel,
    required List<String> frictionSteps,
  }) {
    if (!canAddSwap) {
      ref.read(proGateEventProvider.notifier).state =
          'Free plan supports up to 3 active swaps. Upgrade to Pro for unlimited swaps and personalized friction coaching.';
      return;
    }
    final swap = NeuroSwap(
      id: 'swap-${_uuid.v4()}',
      title: title,
      cue: cue,
      badResponse: badResponse,
      interceptAction: interceptAction,
      frictionLevel: frictionLevel,
      frictionSteps: frictionSteps,
      urgeSurfingCompletions: const [],
      slips: const [],
      createdAt: DateTime.now().toIso8601String(),
      isActive: true,
    );
    _save(state.copyWith(swaps: [swap, ...state.swaps]));
  }

  void archiveNeuroSwap(String id) {
    _save(state.copyWith(
      swaps: state.swaps.map((s) => s.id == id ? s.copyWith(isActive: false) : s).toList(),
    ));
  }

  void deleteNeuroSwap(String id) {
    _save(state.copyWith(swaps: state.swaps.where((s) => s.id != id).toList()));
  }

  void logUrgeSurf(String id, {String? notes}) {
    final todayStr = getLocalDateString(DateTime.now());
    const dopamineAward = 15;
    const gabaAward = 30;

    final updatedSwaps = state.swaps.map((swap) {
      if (swap.id != id) return swap;
      final alreadyDone = swap.urgeSurfingCompletions.contains(todayStr);
      final completions = alreadyDone ? swap.urgeSurfingCompletions : [...swap.urgeSurfingCompletions, todayStr];
      return swap.copyWith(urgeSurfingCompletions: completions);
    }).toList();

    final swap = state.swaps.firstWhere((s) => s.id == id);
    final log = NeuroLog(
      id: 'log-${_uuid.v4()}',
      timestamp: DateTime.now().toIso8601String(),
      type: LogType.urgeSurf,
      itemId: id,
      itemTitle: swap.title,
      notes: notes ?? 'Successfully rode out the craving using box breathing.',
      dopamineChange: dopamineAward,
      epinephrineChange: -10,
      gabaChange: gabaAward,
      acetylcholineChange: 10,
    );

    final chem = state.neurochemistry;
    _save(state.copyWith(
      swaps: updatedSwaps,
      logs: [log, ...state.logs],
      dopaminePoints: state.dopaminePoints + dopamineAward + 10,
      neurochemistry: chem.copyWith(
        dopamine: (chem.dopamine + dopamineAward).clamp(0, 100),
        gaba: (chem.gaba + gabaAward).clamp(0, 100),
        epinephrine: (chem.epinephrine - 10).clamp(0, 100),
        acetylcholine: (chem.acetylcholine + 10).clamp(0, 100),
      ),
    ));
  }

  void logSlip(String id, {String? reflection}) {
    final todayStr = getLocalDateString(DateTime.now());
    const epinephrineIncrease = 40;
    const dopamineDrop = -15;

    final updatedSwaps = state.swaps.map((swap) {
      if (swap.id != id) return swap;
      final alreadySlipped = swap.slips.contains(todayStr);
      final slips = alreadySlipped ? swap.slips : [...swap.slips, todayStr];
      return swap.copyWith(slips: slips);
    }).toList();

    final swap = state.swaps.firstWhere((s) => s.id == id);
    final log = NeuroLog(
      id: 'log-${_uuid.v4()}',
      timestamp: DateTime.now().toIso8601String(),
      type: LogType.slip,
      itemId: id,
      itemTitle: swap.title,
      notes: reflection ?? 'Logged a slip. Triggered neural correction alert.',
      dopamineChange: dopamineDrop,
      epinephrineChange: epinephrineIncrease,
      gabaChange: -10,
      acetylcholineChange: 15,
    );

    final chem = state.neurochemistry;
    _save(state.copyWith(
      swaps: updatedSwaps,
      logs: [log, ...state.logs],
      neurochemistry: chem.copyWith(
        dopamine: (chem.dopamine + dopamineDrop).clamp(0, 100),
        epinephrine: (chem.epinephrine + epinephrineIncrease).clamp(0, 100),
        gaba: (chem.gaba - 10).clamp(0, 100),
        acetylcholine: (chem.acetylcholine + 15).clamp(0, 100),
      ),
    ));
  }

  // ── COMEBACKS ────────────────────────────────────────────────────────────

  void acknowledgeComeback(String stackId, String stackTitle, {required bool microActionsCompleted}) {
    final today = getLocalDateString(DateTime.now());
    final boost = microActionsCompleted ? 20 : 10;

    final record = ComebackRecord(
      id: 'comeback-${_uuid.v4()}',
      stackId: stackId,
      date: today,
      microActionsCompleted: microActionsCompleted,
      completedAt: DateTime.now().toIso8601String(),
    );
    final log = NeuroLog(
      id: 'log-${_uuid.v4()}',
      timestamp: DateTime.now().toIso8601String(),
      type: LogType.comeback,
      itemId: stackId,
      itemTitle: stackTitle,
      notes: microActionsCompleted
          ? 'Activated comeback protocol — micro-actions completed.'
          : 'Activated comeback protocol — acknowledged failure, ready to continue.',
      dopamineChange: boost,
      epinephrineChange: -15,
      gabaChange: 15,
      acetylcholineChange: 10,
    );

    final chem = state.neurochemistry;
    _save(state.copyWith(
      comebacks: [record, ...state.comebacks],
      logs: [log, ...state.logs],
      dopaminePoints: state.dopaminePoints + boost,
      neurochemistry: chem.copyWith(
        dopamine: (chem.dopamine + boost).clamp(0, 100),
        epinephrine: (chem.epinephrine - 15).clamp(0, 100),
        gaba: (chem.gaba + 15).clamp(0, 100),
        acetylcholine: (chem.acetylcholine + 10).clamp(0, 100),
      ),
    ));
  }

  List<String> getTodayComebackIds() {
    final today = getLocalDateString(DateTime.now());
    return state.comebacks.where((c) => c.date == today).map((c) => c.stackId).toList();
  }

  // ── PROFILE / PRO ────────────────────────────────────────────────────────

  void setUserProfile({String? name, String? role}) {
    _save(state.copyWith(
      userProfile: state.userProfile.copyWith(name: name, role: role),
    ));
  }

  void setBrainProfile(NeuroBrainProfile profile) {
    _save(state.copyWith(brainProfile: profile));
  }

  void acceptBlueprint() {
    _save(state.copyWith(blueprintAccepted: true));
  }

  void addBlueprintHabits(List<NeuroStack> habits) {
    _save(state.copyWith(stacks: [...habits, ...state.stacks]));
  }

  void submitCheckin(CheckinRecord record) {
    _save(state.copyWith(
      checkinHistory: [record, ...state.checkinHistory],
      lastCheckinDate: record.date,
    ));
  }

  void applyRecalibration(RecalibrationEvent event) {
    var updatedStacks = [...state.stacks];

    for (final sid in event.accepted) {
      final suggestion = event.suggestions.firstWhere((s) => s.id == sid, orElse: () => event.suggestions.first);

      if (suggestion.type == SuggestionType.scaleDown && suggestion.habitId != null && suggestion.replacementTemplateId != null) {
        final template = findTemplate(suggestion.replacementTemplateId!);
        if (template != null) {
          updatedStacks = updatedStacks.map((s) {
            if (s.id != suggestion.habitId) return s;
            return s.copyWith(
              title: template.title,
              anchorCue: template.anchorCue,
              action: template.action,
              reward: template.reward,
              completions: [],
              streak: 0,
              myelinationLevel: 0,
            );
          }).toList();
        }
      }

      if (suggestion.type == SuggestionType.replace && suggestion.habitId != null && suggestion.replacementTemplateId != null) {
        final template = findTemplate(suggestion.replacementTemplateId!);
        if (template != null) {
          updatedStacks = updatedStacks.map((s) => s.id == suggestion.habitId ? s.copyWith(isActive: false) : s).toList();
          final newStack = NeuroStack(
            id: 'stack-${_uuid.v4()}',
            title: template.title,
            anchorCue: template.anchorCue,
            action: template.action,
            reward: template.reward,
            category: template.category,
            acetylcholineDuration: 10,
            myelinationLevel: 0,
            streak: 0,
            completions: const [],
            createdAt: DateTime.now().toIso8601String(),
            isActive: true,
          );
          updatedStacks = [newStack, ...updatedStacks];
        }
      }
    }

    final updatedCheckins = state.checkinHistory.isEmpty
        ? state.checkinHistory
        : [state.checkinHistory.first.copyWith(recalibrationApplied: true), ...state.checkinHistory.skip(1)];

    _save(state.copyWith(
      stacks: updatedStacks,
      checkinHistory: updatedCheckins,
      recalibrationLog: [event, ...state.recalibrationLog],
    ));
  }

  void upgradeToPro() => _save(state.copyWith(isPro: true));

  void completeOnboarding() => _save(state.copyWith(onboardingComplete: true, dopaminePoints: 50));

  // ── GLOBAL ────────────────────────────────────────────────────────────────

  void decayNeurochemistry() {
    final chem = state.neurochemistry;
    _save(state.copyWith(
      neurochemistry: Neurochemistry(
        dopamine: decayNeurochemical(chem.dopamine),
        acetylcholine: decayNeurochemical(chem.acetylcholine),
        epinephrine: decayNeurochemical(chem.epinephrine),
        gaba: decayNeurochemical(chem.gaba),
      ),
    ));
  }

  void resetAllData() {
    _save(NeuroState.initial());
  }
}

final neuroProvider = NotifierProvider<NeuroNotifier, NeuroState>(NeuroNotifier.new);
