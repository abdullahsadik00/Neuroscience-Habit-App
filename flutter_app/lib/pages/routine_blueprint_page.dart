import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../providers/neuro_provider.dart';
import '../models/models.dart';
import '../data/habit_library.dart';
import '../utils/blueprint_engine.dart';
import '../theme/app_theme.dart';

const _uuid = Uuid();

class RoutineBlueprintPage extends ConsumerStatefulWidget {
  const RoutineBlueprintPage({super.key});

  @override
  ConsumerState<RoutineBlueprintPage> createState() => _RoutineBlueprintPageState();
}

class _RoutineBlueprintPageState extends ConsumerState<RoutineBlueprintPage> {
  late List<HabitTemplate> _habits;
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    final state = ref.read(neuroProvider);
    _habits = state.brainProfile != null
        ? buildBlueprint(state.brainProfile!, state.neurochemistry)
        : habitLibrary.take(5).toList();
    _selectedIds = _habits.map((h) => h.id).toSet();
  }

  void _accept() {
    final selected = _habits.where((h) => _selectedIds.contains(h.id)).toList();
    final stacks = selected.map((h) => NeuroStack(
      id: 'stack-${_uuid.v4()}',
      title: h.title,
      anchorCue: h.anchorCue,
      action: h.action,
      reward: h.reward,
      category: h.category,
      acetylcholineDuration: 10,
      myelinationLevel: 0,
      streak: 0,
      completions: const [],
      createdAt: DateTime.now().toIso8601String(),
      isActive: true,
    )).toList();

    ref.read(neuroProvider.notifier).addBlueprintHabits(stacks);
    ref.read(neuroProvider.notifier).acceptBlueprint();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Your Personalized Blueprint',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: const Color(0xFF6366F1)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your Starter Routine',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ).animate().fadeIn(),
                    const SizedBox(height: 8),
                    Text(
                      'Based on your brain profile. Deselect any that don\'t fit — you can always add more later.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textSecondary),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final h = _habits[i];
                    final selected = _selectedIds.contains(h.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _BlueprintCard(
                        habit: h,
                        selected: selected,
                        onToggle: () {
                          setState(() {
                            if (selected) {
                              _selectedIds.remove(h.id);
                            } else {
                              _selectedIds.add(h.id);
                            }
                          });
                        },
                      ).animate(delay: (i * 80).ms).fadeIn().slideY(begin: 0.1),
                    );
                  },
                  childCount: _habits.length,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              sliver: SliverToBoxAdapter(
                child: ElevatedButton(
                  onPressed: _selectedIds.isEmpty ? null : _accept,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: Text('Activate ${_selectedIds.length} Habit${_selectedIds.length != 1 ? 's' : ''}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlueprintCard extends StatelessWidget {
  final HabitTemplate habit;
  final bool selected;
  final VoidCallback onToggle;
  const _BlueprintCard({required this.habit, required this.selected, required this.onToggle});

  static const _catColors = {
    HabitCategory.focus: focusColor,
    HabitCategory.wellness: wellnessColor,
    HabitCategory.mindset: mindsetColor,
    HabitCategory.fitness: fitnessColor,
  };

  static const _catLabels = {
    HabitCategory.focus: 'Focus',
    HabitCategory.wellness: 'Wellness',
    HabitCategory.mindset: 'Mindset',
    HabitCategory.fitness: 'Fitness',
  };

  @override
  Widget build(BuildContext context) {
    final color = _catColors[habit.category] ?? focusColor;
    final label = _catLabels[habit.category] ?? '';

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF6366F1) : context.borderColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(habit.duration, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.textSecondary)),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF6366F1) : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? const Color(0xFF6366F1) : context.textSecondary,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(habit.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(habit.description, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.isDark ? const Color(0xFF1E2A45) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(icon: Icons.link, label: 'Cue', value: habit.anchorCue),
                  const SizedBox(height: 6),
                  _InfoRow(icon: Icons.bolt, label: 'Action', value: habit.action),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: context.textSecondary),
        const SizedBox(width: 6),
        Text('$label: ', style: TextStyle(fontSize: 12, color: context.textSecondary, fontWeight: FontWeight.w600)),
        Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: context.textSecondary))),
      ],
    );
  }
}
