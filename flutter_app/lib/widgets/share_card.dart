import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fixed-size card rendered into an image for sharing.
/// Must be placed inside a RepaintBoundary with a GlobalKey.
///
/// Hard-codes all colors — never reads from Theme/context so the
/// capture is identical regardless of the app's current theme.
class ShareCard extends StatelessWidget {
  final int brainScore;
  final int comebackStreak;
  final double recoveryRate;
  final int bestStreak;
  final String? archetypeName;
  final String userName;

  const ShareCard({
    super.key,
    required this.brainScore,
    required this.comebackStreak,
    required this.recoveryRate,
    required this.bestStreak,
    this.archetypeName,
    this.userName = '',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 480,
      child: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F0F1A), Color(0xFF1A1033)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Subtle pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _DotPatternPainter()),
          ),

          // Glow blob top-right
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.18),
              ),
            ),
          ),

          // Glow blob bottom-left
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B5CF6).withOpacity(0.14),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand row
                Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.psychology, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'NeuroSync',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    if (userName.isNotEmpty)
                      Text(
                        userName,
                        style: GoogleFonts.inter(color: const Color(0xFF9CA3AF), fontSize: 12),
                      ),
                  ],
                ),

                const SizedBox(height: 28),

                // Archetype name (if available)
                if (archetypeName != null) ...[
                  Text(
                    archetypeName!,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6366F1),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],

                // Main tagline
                Text(
                  'Recovery stats',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),

                const SizedBox(height: 28),

                // Stats grid — 2×2
                Row(
                  children: [
                    Expanded(child: _StatBlock(value: '$brainScore', label: 'Brain Score', color: const Color(0xFF6366F1))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatBlock(value: '${comebackStreak}d', label: 'Comeback Streak', color: const Color(0xFFF59E0B))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _StatBlock(value: '${recoveryRate.round()}%', label: 'Recovery Rate', color: const Color(0xFF8B5CF6))),
                    const SizedBox(width: 12),
                    Expanded(child: _StatBlock(value: '${bestStreak}d', label: 'Best Streak', color: const Color(0xFF10B981))),
                  ],
                ),

                const Spacer(),

                // Divider
                Container(height: 1, color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 14),

                // Footer
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Built my neural pathways\none comeback at a time.',
                        style: GoogleFonts.inter(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                    Text(
                      'neurosync.app',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6366F1),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBlock({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// Subtle dot grid pattern for depth
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
