import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/neuro_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../utils/neuro_helpers.dart';
import '../utils/stats_helpers.dart';
import '../utils/comeback_helpers.dart';
import '../utils/recalibration_engine.dart';
import '../widgets/neurochem_hud.dart';
import '../widgets/stats_bar.dart';
import '../widgets/habit_card.dart';
import '../widgets/swap_card.dart';
import '../widgets/comeback_protocol.dart';
import '../widgets/add_habit_sheet.dart';
import '../widgets/add_swap_sheet.dart';
import '../widgets/weekly_checkin_modal.dart';
import '../widgets/recalibration_sheet.dart';
import '../widgets/recovery_playbook.dart';

const _checkinIntervalDays = 7;

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _checkinShown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkCheckin();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkCheckin() {
    if (_checkinShown) return;
    final state = ref.read(neuroProvider);
    if (state.lastCheckinDate == null) {
      _showCheckin();
      return;
    }
    final lastDate = DateTime.parse(state.lastCheckinDate!);
    final daysSince = DateTime.now().difference(lastDate).inDays;
    if (daysSince >= _checkinIntervalDays) {
      _showCheckin();
    }
  }

  void _showCheckin() {
    setState(() => _checkinShown = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const WeeklyCheckinModal(),
      ).then((record) {
        if (record is CheckinRecord && mounted) {
          _checkRecalibration(record);
        }
      });
    });
  }

  void _checkRecalibration(CheckinRecord record) {
    final state = ref.read(neuroProvider);
    final suggestions = runRecalibration(state.stacks, state.checkinHistory, state.brainProfile);
    if (suggestions.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecalibrationSheet(suggestions: suggestions),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(neuroProvider);
    final activeStacks = state.stacks.where((s) => s.isActive).toList();
    final today = getLocalDateString(DateTime.now());
    final todayComebacks = ref.read(neuroProvider.notifier).getTodayComebackIds();
    final missedStacks = getMissedStacks(activeStacks, todayComebacks);
    final camebacksThisMonth = getComebacksThisMonth(state.comebacks);
    final canShowComeback = state.isPro || camebacksThisMonth < 3;

    final brainScore = calcBrainScore(state.stacks, state.comebacks, state.neurochemistry);
    final bestStreak = getBestStreak(state.stacks);
    final daysIn = getDaysInSystem(state.stacks);
    final recoveryRate = calcRecoveryRate(state.comebacks);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.userProfile.name.isNotEmpty ? 'Hey, ${state.userProfile.name}' : 'NeuroFlow',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              _dayGreeting(),
              style: TextStyle(fontSize: 12, color: context.textSecondary),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt, color: Color(0xFF6366F1), size: 14),
                  const SizedBox(width: 4),
                  Text('${state.dopaminePoints}', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(ref.watch(themeModeProvider) == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  ref.read(themeModeProvider) == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                NeurochemHUD(neurochemistry: state.neurochemistry).animate().fadeIn(),
                const SizedBox(height: 12),
                StatsBar(
                  brainScore: brainScore,
                  bestStreak: bestStreak,
                  daysInSystem: daysIn,
                  recoveryRate: recoveryRate,
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 12),
                if (canShowComeback && missedStacks.isNotEmpty)
                  ComebackProtocolBanner(missedStacks: missedStacks),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Habits'),
              Tab(text: 'Swaps'),
              Tab(text: 'Activity'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _HabitsTab(stacks: activeStacks, comebacks: state.comebacks, today: today),
                _SwapsTab(swaps: state.swaps.where((s) => s.isActive).toList()),
                _ActivityTab(
                  logs: state.logs,
                  stacks: state.stacks,
                  comebacks: state.comebacks,
                  swaps: state.swaps,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  String _dayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget? _buildFab(BuildContext context) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        if (_tabController.index == 2) return const SizedBox.shrink();
        return FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _tabController.index == 0 ? const AddHabitSheet() : const AddSwapSheet(),
            );
          },
          backgroundColor: const Color(0xFF6366F1),
          child: const Icon(Icons.add, color: Colors.white),
        );
      },
    );
  }
}

class _HabitsTab extends ConsumerWidget {
  final List<NeuroStack> stacks;
  final List<ComebackRecord> comebacks;
  final String today;
  const _HabitsTab({required this.stacks, required this.comebacks, required this.today});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (stacks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_outlined, size: 48, color: Color(0xFF6366F1)),
            const SizedBox(height: 16),
            Text('No habits yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Tap + to add your first habit', style: TextStyle(color: context.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: stacks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final stack = stacks[i];
        final completedToday = stack.completions.contains(today);
        return HabitCard(
          stack: stack,
          comebacks: comebacks,
          completedToday: completedToday,
          onComplete: () => ref.read(neuroProvider.notifier).completeNeuroStack(stack.id),
          onDelete: () => ref.read(neuroProvider.notifier).deleteNeuroStack(stack.id),
        ).animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.05);
      },
    );
  }
}

class _SwapsTab extends ConsumerWidget {
  final List<NeuroSwap> swaps;
  const _SwapsTab({required this.swaps});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (swaps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.swap_horiz, size: 48, color: Color(0xFF10B981)),
            const SizedBox(height: 16),
            Text('No swaps yet', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Tap + to replace a bad habit', style: TextStyle(color: context.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: swaps.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final swap = swaps[i];
        return SwapCard(
          swap: swap,
          onUrgeSurf: () => ref.read(neuroProvider.notifier).logUrgeSurf(swap.id),
          onSlip: () => ref.read(neuroProvider.notifier).logSlip(swap.id),
          onDelete: () => ref.read(neuroProvider.notifier).deleteNeuroSwap(swap.id),
        ).animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.05);
      },
    );
  }
}

class _ActivityTab extends StatelessWidget {
  final List<NeuroLog> logs;
  final List<NeuroStack> stacks;
  final List<ComebackRecord> comebacks;
  final List<NeuroSwap> swaps;
  const _ActivityTab({required this.logs, required this.stacks, required this.comebacks, required this.swaps});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: RecoveryPlaybook(stacks: stacks, comebacks: comebacks, swaps: swaps),
          ),
        ),
        if (logs.isEmpty)
          const SliverFillRemaining(
            child: Center(child: Text('No activity yet.')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final log = logs[i];
                  return _LogItem(log: log).animate(delay: (i * 40).ms).fadeIn();
                },
                childCount: logs.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _LogItem extends StatelessWidget {
  final NeuroLog log;
  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (log.type) {
      LogType.completion => (Icons.check_circle, const Color(0xFF10B981), 'Completed'),
      LogType.urgeSurf => (Icons.waves, const Color(0xFF3B82F6), 'Urge Surfed'),
      LogType.slip => (Icons.warning_amber, const Color(0xFFEF4444), 'Slip'),
      LogType.comeback => (Icons.arrow_back, const Color(0xFFF59E0B), 'Comeback'),
    };

    final time = DateTime.tryParse(log.timestamp);
    final timeStr = time != null
        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.itemTitle, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(label, style: TextStyle(fontSize: 11, color: color)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (log.dopamineChange > 0)
                  Text('+${log.dopamineChange} DA', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.w600)),
                Text(timeStr, style: TextStyle(fontSize: 10, color: context.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
