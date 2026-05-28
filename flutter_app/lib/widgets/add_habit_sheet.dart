import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/neuro_provider.dart';
import '../models/models.dart';
import '../data/habit_library.dart';
import '../theme/app_theme.dart';

enum _AddMode { custom, library }

class AddHabitSheet extends ConsumerStatefulWidget {
  const AddHabitSheet({super.key});

  @override
  ConsumerState<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<AddHabitSheet> {
  _AddMode _mode = _AddMode.library;
  HabitCategory _filterCat = HabitCategory.focus;

  final _titleCtrl = TextEditingController();
  final _cueCtrl = TextEditingController();
  final _actionCtrl = TextEditingController();
  final _rewardCtrl = TextEditingController();
  HabitCategory _customCat = HabitCategory.focus;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _cueCtrl.dispose();
    _actionCtrl.dispose();
    _rewardCtrl.dispose();
    super.dispose();
  }

  void _addFromLibrary(HabitTemplate t) {
    ref.read(neuroProvider.notifier).addNeuroStack(
      title: t.title,
      anchorCue: t.anchorCue,
      action: t.action,
      reward: t.reward,
      category: t.category,
      acetylcholineDuration: 10,
    );
    Navigator.pop(context);
  }

  void _addCustom() {
    if (_titleCtrl.text.trim().isEmpty) return;
    ref.read(neuroProvider.notifier).addNeuroStack(
      title: _titleCtrl.text.trim(),
      anchorCue: _cueCtrl.text.trim(),
      action: _actionCtrl.text.trim(),
      reward: _rewardCtrl.text.trim(),
      category: _customCat,
      acetylcholineDuration: 10,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: context.bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Text('Add Habit', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  SegmentedButton<_AddMode>(
                    segments: const [
                      ButtonSegment(value: _AddMode.library, label: Text('Library')),
                      ButtonSegment(value: _AddMode.custom, label: Text('Custom')),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() => _mode = s.first),
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _mode == _AddMode.library ? _buildLibrary(controller) : _buildCustom(controller),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibrary(ScrollController controller) {
    final filtered = habitLibrary.where((h) => h.category == _filterCat).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: HabitCategory.values.map((cat) {
                final selected = cat == _filterCat;
                final colors = {
                  HabitCategory.focus: focusColor,
                  HabitCategory.wellness: wellnessColor,
                  HabitCategory.mindset: mindsetColor,
                  HabitCategory.fitness: fitnessColor,
                };
                final labels = {
                  HabitCategory.focus: 'Focus',
                  HabitCategory.wellness: 'Wellness',
                  HabitCategory.mindset: 'Mindset',
                  HabitCategory.fitness: 'Fitness',
                };
                final color = colors[cat]!;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(labels[cat]!),
                    selected: selected,
                    onSelected: (_) => setState(() => _filterCat = cat),
                    selectedColor: color.withOpacity(0.2),
                    checkmarkColor: color,
                    labelStyle: TextStyle(color: selected ? color : null, fontWeight: selected ? FontWeight.w600 : null),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final h = filtered[i];
              return GestureDetector(
                onTap: () => _addFromLibrary(h),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(h.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(6)),
                            child: Text(h.duration, style: TextStyle(fontSize: 11, color: context.textSecondary)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(h.description, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                      const SizedBox(height: 6),
                      Text('Cue: ${h.anchorCue}', style: TextStyle(fontSize: 11, color: context.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCustom(ScrollController controller) {
    return SingleChildScrollView(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Field(label: 'Habit Title', controller: _titleCtrl, hint: 'e.g. Morning Deep Work'),
          _Field(label: 'Anchor Cue', controller: _cueCtrl, hint: 'After I...'),
          _Field(label: 'Action', controller: _actionCtrl, hint: 'I will...'),
          _Field(label: 'Reward', controller: _rewardCtrl, hint: 'I will reward myself with...'),
          const SizedBox(height: 16),
          Text('Category', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: HabitCategory.values.map((cat) {
              final colors = {
                HabitCategory.focus: focusColor,
                HabitCategory.wellness: wellnessColor,
                HabitCategory.mindset: mindsetColor,
                HabitCategory.fitness: fitnessColor,
              };
              final labels = {
                HabitCategory.focus: 'Focus',
                HabitCategory.wellness: 'Wellness',
                HabitCategory.mindset: 'Mindset',
                HabitCategory.fitness: 'Fitness',
              };
              final selected = _customCat == cat;
              final color = colors[cat]!;
              return FilterChip(
                label: Text(labels[cat]!),
                selected: selected,
                onSelected: (_) => setState(() => _customCat = cat),
                selectedColor: color.withOpacity(0.2),
                labelStyle: TextStyle(color: selected ? color : null),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _addCustom, child: const Text('Add Habit')),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  const _Field({required this.label, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        TextField(controller: controller, decoration: InputDecoration(hintText: hint)),
      ],
    );
  }
}
