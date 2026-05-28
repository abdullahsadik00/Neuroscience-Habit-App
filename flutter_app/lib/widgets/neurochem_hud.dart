import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class NeurochemHUD extends StatelessWidget {
  final Neurochemistry neurochemistry;
  const NeurochemHUD({super.key, required this.neurochemistry});

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              const Icon(Icons.science_outlined, size: 16, color: Color(0xFF6366F1)),
              const SizedBox(width: 8),
              Text('Neurochemistry', style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: const Color(0xFF6366F1),
                fontWeight: FontWeight.w600,
              )),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ChemBar(label: 'DA', value: neurochemistry.dopamine, color: dopamineColor, tooltip: 'Dopamine').animate().fadeIn(delay: 100.ms),
              const SizedBox(width: 8),
              _ChemBar(label: 'ACh', value: neurochemistry.acetylcholine, color: acetylcholineColor, tooltip: 'Acetylcholine').animate().fadeIn(delay: 150.ms),
              const SizedBox(width: 8),
              _ChemBar(label: 'EPI', value: neurochemistry.epinephrine, color: epinephrineColor, tooltip: 'Epinephrine').animate().fadeIn(delay: 200.ms),
              const SizedBox(width: 8),
              _ChemBar(label: 'GABA', value: neurochemistry.gaba, color: gabaColor, tooltip: 'GABA').animate().fadeIn(delay: 250.ms),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChemBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final String tooltip;
  const _ChemBar({required this.label, required this.value, required this.color, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final pct = (value / 100).clamp(0.0, 1.0);
    return Expanded(
      child: Tooltip(
        message: '$tooltip: ${value.round()}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
                Text('${value.round()}', style: TextStyle(fontSize: 10, color: context.textSecondary)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
