import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
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
import '../widgets/brain_profile_card.dart';
import '../widgets/share_card.dart';
import 'upgrade_page.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCheckin());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkCheckin() {
    if (_checkinShown) return;
    final state = ref.read(neuroProvider);
    if (state.lastCheckinDate == null) { _showCheckin(); return; }
    final daysSince = DateTime.now().difference(DateTime.parse(state.lastCheckinDate!)).inDays;
    if (daysSince >= _checkinIntervalDays) _showCheckin();
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
        if (record is CheckinRecord && mounted) _checkRecalibration(record);
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

  void _showMilestoneCelebration(String habitTitle, int milestone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              const Text('🧠', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$milestone% Neural Pathway!',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '"$habitTitle" is becoming automatic.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showProGate(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.psychology, color: Color(0xFF6366F1)),
            const SizedBox(width: 8),
            const Text('Upgrade to Pro'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Not now')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: launch Stripe paywall when Stripe is integrated
              ref.read(neuroProvider.notifier).upgradeToPro();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pro unlocked! (Stripe coming soon)')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
            child: const Text('Upgrade — \$9/mo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers for side-effect events
    ref.listen<(String, int)?>(milestoneEventProvider, (_, event) {
      if (event != null && mounted) {
        _showMilestoneCelebration(event.$1, event.$2);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(milestoneEventProvider.notifier).state = null;
        });
      }
    });
    ref.listen<String?>(proGateEventProvider, (_, message) {
      if (message != null && mounted) {
        _showProGate(message);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) ref.read(proGateEventProvider.notifier).state = null;
        });
      }
    });

    final state = ref.watch(neuroProvider);
    final activeStacks = state.stacks.where((s) => s.isActive).toList();
    final today = getLocalDateString(DateTime.now());
    final todayComebacks = ref.read(neuroProvider.notifier).getTodayComebackIds();
    final missedStacks = getMissedStacks(activeStacks, todayComebacks);
    final camebacksThisMonth = getComebacksThisMonth(state.comebacks);
    final canShowComeback = state.isPro || camebacksThisMonth < 3;

    final brainScore = calcBrainScore(state.stacks, state.comebacks, state.neurochemistry);
    final comebackStreak = getComebackStreak(state.comebacks);
    final bestStreak = getBestStreak(state.stacks);
    final recoveryRate = calcRecoveryRate(state.comebacks);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.userProfile.name.isNotEmpty ? 'Hey, ${state.userProfile.name}' : 'NeuroSync',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(_dayGreeting(), style: TextStyle(fontSize: 12, color: context.textSecondary)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
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
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Share your stats',
            onPressed: () => _showShareSheet(
              context,
              brainScore: brainScore,
              comebackStreak: comebackStreak,
              recoveryRate: recoveryRate,
              bestStreak: bestStreak,
              archetypeName: state.brainProfile != null
                  ? _archetypeName(state.brainProfile!)
                  : null,
              userName: state.userProfile.name,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined),
            tooltip: 'Upgrade to Pro',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradePage())),
          ),
          IconButton(
            icon: Icon(ref.watch(themeModeProvider) == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  ref.read(themeModeProvider) == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
          _SignOutButton(),
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
                  comebackStreak: comebackStreak,
                  bestStreak: bestStreak,
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
                _HabitsTab(
                  stacks: state.stacks,
                  comebacks: state.comebacks,
                  today: today,
                ),
                _SwapsTab(swaps: state.swaps.where((s) => s.isActive).toList()),
                _ActivityTab(
                  logs: state.logs,
                  stacks: state.stacks,
                  comebacks: state.comebacks,
                  swaps: state.swaps,
                  brainProfile: state.brainProfile,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context, state),
    );
  }

  static String _archetypeName(NeuroBrainProfile p) {
    const names = {
      'perfectionist-feelBetter': 'The Exhausted Achiever',
      'perfectionist-performBetter': 'The Precision Driver',
      'perfectionist-becomeSomeone': 'The Identity Builder',
      'perfectionist-survive': 'The Cornered Perfectionist',
      'avoider-feelBetter': 'The Comfort Seeker',
      'avoider-performBetter': 'The Quiet Competitor',
      'avoider-becomeSomeone': 'The Reluctant Transformer',
      'avoider-survive': 'The Minimal Risk-Taker',
      'analyst-feelBetter': 'The Thoughtful Healer',
      'analyst-performBetter': 'The Systems Optimizer',
      'analyst-becomeSomeone': 'The Deliberate Builder',
      'analyst-survive': 'The Calculated Survivor',
      'drifter-feelBetter': 'The Restless Dreamer',
      'drifter-performBetter': 'The Inconsistent Sprinter',
      'drifter-becomeSomeone': 'The Aspiring Self',
      'drifter-survive': 'The Day-to-Day Navigator',
    };
    return names['${p.failureStyle.name}-${p.coreDriver.name}'] ?? 'The Recovery Builder';
  }

  void _showShareSheet(
    BuildContext context, {
    required int brainScore,
    required int comebackStreak,
    required double recoveryRate,
    required int bestStreak,
    String? archetypeName,
    String userName = '',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShareSheet(
        brainScore: brainScore,
        comebackStreak: comebackStreak,
        recoveryRate: recoveryRate,
        bestStreak: bestStreak,
        archetypeName: archetypeName,
        userName: userName,
      ),
    );
  }

  String _dayGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Widget? _buildFab(BuildContext context, NeuroState state) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, _) {
        if (_tabController.index == 2) return const SizedBox.shrink();
        return FloatingActionButton(
          onPressed: () {
            if (_tabController.index == 0) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddHabitSheet(),
              );
            } else {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddSwapSheet(),
              );
            }
          },
          backgroundColor: const Color(0xFF6366F1),
          child: const Icon(Icons.add, color: Colors.white),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Habits Tab
// ─────────────────────────────────────────────────────────────────────────────

class _HabitsTab extends ConsumerStatefulWidget {
  final List<NeuroStack> stacks;
  final List<ComebackRecord> comebacks;
  final String today;
  const _HabitsTab({required this.stacks, required this.comebacks, required this.today});

  @override
  ConsumerState<_HabitsTab> createState() => _HabitsTabState();
}

class _HabitsTabState extends ConsumerState<_HabitsTab> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.stacks.where((s) => s.isActive).toList();
    final archived = widget.stacks.where((s) => !s.isActive).toList();

    if (active.isEmpty && archived.isEmpty) {
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

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Active habits
        ...active.asMap().entries.map((e) {
          final stack = e.value;
          final completedToday = stack.completions.contains(widget.today);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HabitCard(
              stack: stack,
              comebacks: widget.comebacks,
              completedToday: completedToday,
              onComplete: () => ref.read(neuroProvider.notifier).completeNeuroStack(stack.id),
              onArchive: () => ref.read(neuroProvider.notifier).archiveNeuroStack(stack.id),
            ).animate(delay: (e.key * 60).ms).fadeIn().slideY(begin: 0.05),
          );
        }),

        // Archived section
        if (archived.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => setState(() => _showArchived = !_showArchived),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.archive_outlined, size: 16, color: context.textSecondary),
                  const SizedBox(width: 8),
                  Text('Archived (${archived.length})', style: TextStyle(color: context.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Icon(_showArchived ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 18, color: context.textSecondary),
                ],
              ),
            ),
          ),
          if (_showArchived) ...[
            const SizedBox(height: 8),
            ...archived.map((stack) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: context.cardBg.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stack.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          Text('${stack.streak}d streak · ${stack.myelinationLevel.round()}% pathway', style: TextStyle(fontSize: 11, color: context.textSecondary)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.read(neuroProvider.notifier).unarchiveNeuroStack(stack.id),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Restore', style: TextStyle(fontSize: 12, color: Color(0xFF6366F1))),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swaps Tab
// ─────────────────────────────────────────────────────────────────────────────

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
          onDelete: () => ref.read(neuroProvider.notifier).archiveNeuroSwap(swap.id),
        ).animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.05);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity Tab
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityTab extends StatelessWidget {
  final List<NeuroLog> logs;
  final List<NeuroStack> stacks;
  final List<ComebackRecord> comebacks;
  final List<NeuroSwap> swaps;
  final NeuroBrainProfile? brainProfile;

  const _ActivityTab({
    required this.logs,
    required this.stacks,
    required this.comebacks,
    required this.swaps,
    required this.brainProfile,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                RecoveryPlaybook(stacks: stacks, comebacks: comebacks, swaps: swaps),
                if (brainProfile != null) ...[
                  const SizedBox(height: 16),
                  Consumer(
                    builder: (context, ref, _) => BrainProfileCard(
                      profile: brainProfile!,
                      onRetake: () {
                        // Reset brain profile so routing goes back to BrainAssessmentPage
                        ref.read(neuroProvider.notifier).setBrainProfile(brainProfile!);
                        // TODO: navigate to BrainAssessmentPage for retake
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Retake: navigate to Brain Assessment (coming soon)')),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (logs.isEmpty)
          const SliverFillRemaining(child: SizedBox.shrink())
        else ...[
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text('Recent Activity', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _LogItem(log: logs[i]).animate(delay: (i * 40).ms).fadeIn(),
                childCount: logs.length,
              ),
            ),
          ),
        ],
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
      LogType.comeback => (Icons.replay_circle_filled, const Color(0xFFF59E0B), 'Comeback'),
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
              width: 36, height: 36,
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

// ─────────────────────────────────────────────────────────────────────────────
// Share sheet — previews the card, then captures and shares as PNG image
// ─────────────────────────────────────────────────────────────────────────────

class _ShareSheet extends StatefulWidget {
  final int brainScore;
  final int comebackStreak;
  final double recoveryRate;
  final int bestStreak;
  final String? archetypeName;
  final String userName;

  const _ShareSheet({
    required this.brainScore,
    required this.comebackStreak,
    required this.recoveryRate,
    required this.bestStreak,
    this.archetypeName,
    this.userName = '',
  });

  @override
  State<_ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<_ShareSheet> {
  final _cardKey = GlobalKey();
  bool _capturing = false;

  Future<void> _captureAndShare() async {
    setState(() => _capturing = true);
    try {
      // Wait one frame so the card is fully rendered at natural size
      await Future.delayed(const Duration(milliseconds: 50));

      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/neurosync_stats.png');
      await file.writeAsBytes(bytes.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        text: 'My NeuroSync recovery stats 🧠',
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not capture image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Share your stats',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Card preview — wrapped in RepaintBoundary for capture
          Center(
            child: RepaintBoundary(
              key: _cardKey,
              child: ShareCard(
                brainScore: widget.brainScore,
                comebackStreak: widget.comebackStreak,
                recoveryRate: widget.recoveryRate,
                bestStreak: widget.bestStreak,
                archetypeName: widget.archetypeName,
                userName: widget.userName,
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _capturing ? null : _captureAndShare,
              icon: _capturing
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.ios_share, size: 18),
              label: Text(_capturing ? 'Capturing…' : 'Share image'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sign-out button (only visible when Supabase is configured + user is signed in)
// ─────────────────────────────────────────────────────────────────────────────

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    bool supabaseReady = false;
    try {
      Supabase.instance.client;
      supabaseReady = true;
    } catch (_) {}

    if (!supabaseReady) return const SizedBox.shrink();
    if (Supabase.instance.client.auth.currentUser == null) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Sign out',
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Sign out?'),
            content: const Text('Your data is saved to the cloud. You can sign back in anytime.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                child: const Text('Sign out'),
              ),
            ],
          ),
        );
        if (confirmed == true) await Supabase.instance.client.auth.signOut();
      },
    );
  }
}
