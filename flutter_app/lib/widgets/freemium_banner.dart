// =============================================================================
// freemium_banner.dart
//
// An inline strip that tells free-tier users how many Comeback Protocol
// activations they have left this calendar month.
//
// BEHAVIOUR:
//   - Hidden for Pro users (returns SizedBox.shrink).
//   - Shows a "zap" state with remaining count when limit is not yet hit.
//   - Flips to a "lock" state with a red accent when the limit is reached.
//   - Tapping "Upgrade" calls the [onUpgrade] callback (navigates to paywall).
//
// PROPS:
//   - comebacksThisMonth  — how many comebacks the user has logged this month.
//   - isPro               — if true the widget is invisible.
//   - onUpgrade           — callback fired when the upgrade button is tapped.
// =============================================================================

import 'package:flutter/material.dart';

/// How many free Comeback Protocol activations a free-tier user gets per month.
const int _freeLimit = 3;

class FreemiumBanner extends StatelessWidget {
  const FreemiumBanner({
    super.key,
    required this.comebacksThisMonth,
    required this.isPro,
    required this.onUpgrade,
  });

  final int comebacksThisMonth;
  final bool isPro;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    if (isPro) return const SizedBox.shrink();

    final used = comebacksThisMonth.clamp(0, _freeLimit);
    final remaining = _freeLimit - used;
    final atLimit = remaining == 0;

    final accent = atLimit ? const Color(0xFFEF4444) : const Color(0xFF6366F1);
    final accentBg = atLimit
        ? const Color(0xFFEF4444).withOpacity(0.08)
        : const Color(0xFF6366F1).withOpacity(0.08);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: accent, width: 2.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              atLimit ? Icons.lock_outline_rounded : Icons.bolt_rounded,
              size: 14,
              color: accent,
            ),
          ),
          const SizedBox(width: 10),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  atLimit
                      ? 'Free comeback limit reached'
                      : '$remaining free comeback${remaining != 1 ? 's' : ''} remaining',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: atLimit
                        ? accent
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  atLimit
                      ? 'Unlock unlimited comebacks + full recovery analytics'
                      : '$used of $_freeLimit used · Full Recovery Engine from \$9/mo',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Upgrade button
          GestureDetector(
            onTap: onUpgrade,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: accentBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withOpacity(0.3)),
              ),
              child: Text(
                'Upgrade',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
