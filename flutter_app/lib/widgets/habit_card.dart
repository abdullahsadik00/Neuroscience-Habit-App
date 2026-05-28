import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../utils/stats_helpers.dart';
import '../theme/app_theme.dart';
import 'weekly_grid.dart';

class HabitCard extends StatelessWidget {
  final NeuroStack stack;
  final List<ComebackRecord> comebacks;
  final bool completedToday;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const HabitCard({
    super.key,
    required this.stack,
    required this.comebacks,
    required this.completedToday,
    required this.onComplete,
    required this.onDelete,
  });

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
    final color = _catColors[stack.category] ?? focusColor;
    final label = _catLabels[stack.category] ?? '';
    final weekDays = getWeekGrid(stack, comebacks);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
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
              const Spacer(),
              if (stack.streak > 0) ...[
                const Icon(Icons.local_fire_department, color: Color(0xFFF59E0B), size: 14),
                const SizedBox(width: 4),
                Text('${stack.streak}d', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
              ],
              PopupMenuButton<String>(
                iconSize: 18,
                onSelected: (v) { if (v == 'delete') onDelete(); },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'delete', child: Text('Delete habit')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(stack.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(stack.anchorCue, style: TextStyle(fontSize: 12, color: context.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),

          const SizedBox(height: 12),

          // Myelination bar
          Row(
            children: [
              Text('Neural Pathway', style: TextStyle(fontSize: 11, color: context.textSecondary)),
              const Spacer(),
              Text('${stack.myelinationLevel.round()}%', style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stack.myelinationLevel / 100,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),

          const SizedBox(height: 12),

          // Weekly grid
          WeeklyGrid(days: weekDays),

          const SizedBox(height: 12),

          // Complete button
          SizedBox(
            width: double.infinity,
            child: completedToday
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                        SizedBox(width: 8),
                        Text('Completed Today', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  )
                : ElevatedButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      minimumSize: const Size(double.infinity, 40),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
