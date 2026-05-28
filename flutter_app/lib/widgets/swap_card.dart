import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/neuro_helpers.dart';
import '../theme/app_theme.dart';

class SwapCard extends StatefulWidget {
  final NeuroSwap swap;
  final VoidCallback onUrgeSurf;
  final VoidCallback onSlip;
  final VoidCallback onDelete;

  const SwapCard({
    super.key,
    required this.swap,
    required this.onUrgeSurf,
    required this.onSlip,
    required this.onDelete,
  });

  @override
  State<SwapCard> createState() => _SwapCardState();
}

class _SwapCardState extends State<SwapCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final today = getLocalDateString(DateTime.now());
    final surfedToday = widget.swap.urgeSurfingCompletions.contains(today);
    final slippedToday = widget.swap.slips.contains(today);

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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Swap', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Text(
                '${widget.swap.urgeSurfingCompletions.length} surf${widget.swap.urgeSurfingCompletions.length != 1 ? 's' : ''}',
                style: TextStyle(fontSize: 11, color: context.textSecondary),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                iconSize: 18,
                onSelected: (v) { if (v == 'delete') widget.onDelete(); },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'delete', child: Text('Delete swap')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(widget.swap.title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            'When: ${widget.swap.cue}',
            style: TextStyle(fontSize: 12, color: context.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Friction steps (collapsible)
          if (widget.swap.frictionSteps.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: context.textSecondary),
                  const SizedBox(width: 6),
                  Text('Friction barriers (${widget.swap.frictionLevel}/5)', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                  const Spacer(),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 16, color: context.textSecondary),
                ],
              ),
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              ...widget.swap.frictionSteps.map((step) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 6, color: context.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(step, style: TextStyle(fontSize: 12, color: context.textSecondary))),
                  ],
                ),
              )),
            ],
          ],

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: surfedToday
                    ? _DoneChip(label: 'Surfed!', color: const Color(0xFF10B981))
                    : _ActionButton(
                        label: 'Urge Surfed',
                        icon: Icons.waves,
                        color: const Color(0xFF10B981),
                        onTap: widget.onUrgeSurf,
                      ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: slippedToday
                    ? _DoneChip(label: 'Logged', color: const Color(0xFFEF4444))
                    : _ActionButton(
                        label: 'Slipped',
                        icon: Icons.warning_amber_outlined,
                        color: const Color(0xFFEF4444),
                        onTap: widget.onSlip,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _DoneChip extends StatelessWidget {
  final String label;
  final Color color;
  const _DoneChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
