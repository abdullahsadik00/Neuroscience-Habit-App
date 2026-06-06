// =============================================================================
// comeback_gate_modal.dart
//
// A full-screen overlay modal shown when a free-tier user has exhausted their
// 3 monthly Comeback Protocol activations and taps the comeback banner.
//
// BEHAVIOUR:
//   - Blurred background scrim; tapping the scrim calls [onDismiss].
//   - Card slides in with a subtle scale + y-offset animation.
//   - "Upgrade to Pro" button calls [onUpgrade] then auto-dismisses.
//   - "Maybe later" text button calls [onDismiss].
//
// USAGE (from dashboard):
//   showDialog(
//     context: context,
//     barrierColor: Colors.transparent,
//     builder: (_) => ComebackGateModal(
//       used: camebacksThisMonth,
//       onUpgrade: () { /* navigate to upgrade page */ },
//       onDismiss: () => Navigator.of(context).pop(),
//     ),
//   );
// =============================================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ComebackGateModal extends StatelessWidget {
  const ComebackGateModal({
    super.key,
    required this.used,
    required this.onUpgrade,
    required this.onDismiss,
  });

  /// How many comebacks the user has used this month (displayed in the copy).
  final int used;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  static const int _freeLimit = 3;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // ── Blurred scrim ──────────────────────────────────────────────────
          GestureDetector(
            onTap: onDismiss,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                color: Colors.black.withOpacity(isDark ? 0.55 : 0.35),
              ),
            ),
          ),

          // ── Card ──────────────────────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _ModalCard(
                used: used,
                onUpgrade: onUpgrade,
                onDismiss: onDismiss,
              )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1, 1),
                    duration: 220.ms,
                    curve: Curves.easeOutCubic,
                  )
                  .moveY(
                    begin: 8,
                    end: 0,
                    duration: 220.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalCard extends StatelessWidget {
  const _ModalCard({
    required this.used,
    required this.onUpgrade,
    required this.onDismiss,
  });

  final int used;
  final VoidCallback onUpgrade;
  final VoidCallback onDismiss;

  static const int _freeLimit = 3;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1C1C2E) : Colors.white;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Lock icon ───────────────────────────────────────────────
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    size: 22,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Headline ────────────────────────────────────────────────
                Text(
                  'Monthly comeback limit reached',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Body copy ───────────────────────────────────────────────
                Text(
                  "You've used all $_freeLimit free comebacks this month. The Comeback Protocol is the most important part of this system — don't lose access to it.",
                  style: TextStyle(
                    fontSize: 13,
                    color: onSurface.withOpacity(0.65),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Upgrade to Pro for unlimited comebacks, full Recovery Analytics, and the Recalibration Engine.',
                  style: TextStyle(
                    fontSize: 13,
                    color: onSurface.withOpacity(0.65),
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Value prop chip ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF6366F1).withOpacity(0.1)
                        : const Color(0xFFF0F0FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pro unlocks unlimited comebacks, multi-device sync, and Failure Signature analysis.',
                          style: TextStyle(
                            fontSize: 12,
                            color: onSurface.withOpacity(0.65),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Upgrade CTA ─────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      onDismiss();
                      onUpgrade();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Upgrade to Pro — \$9/mo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ── Dismiss link ────────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: onDismiss,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Maybe later',
                        style: TextStyle(
                          fontSize: 12,
                          color: onSurface.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Close (X) button ────────────────────────────────────────────
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.07)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: onSurface.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
