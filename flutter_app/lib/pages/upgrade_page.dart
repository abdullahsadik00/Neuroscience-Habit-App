// TODO SETUP — Stripe integration (3 steps):
//
// 1. Create a Stripe account at https://stripe.com
//    - Create two prices: monthly ($9/mo) and annual ($79/yr)
//    - Enable Stripe Checkout
//    - Copy the payment link URLs into _monthlyUrl and _annualUrl below
//
// 2. Deploy the Supabase Edge Function (see supabase/functions/stripe-webhook/):
//    supabase functions deploy stripe-webhook
//    Set env vars in Supabase dashboard:
//      STRIPE_SECRET_KEY=sk_live_xxx
//      STRIPE_WEBHOOK_SECRET=whsec_xxx
//
// 3. In Stripe dashboard → Webhooks, add endpoint:
//    https://YOUR_PROJECT_ID.supabase.co/functions/v1/stripe-webhook
//    Events: checkout.session.completed, customer.subscription.deleted

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/neuro_provider.dart';
import '../theme/app_theme.dart';

// TODO: Replace with your actual Stripe Checkout payment link URLs
const _monthlyUrl = 'https://buy.stripe.com/YOUR_MONTHLY_LINK';
const _annualUrl = 'https://buy.stripe.com/YOUR_ANNUAL_LINK';

class UpgradePage extends ConsumerWidget {
  const UpgradePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(neuroProvider).isPro;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Pro'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🧠', style: TextStyle(fontSize: 36)),
                  const SizedBox(height: 12),
                  const Text(
                    'NeuroSync Pro',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Built for people who miss habits — and come back stronger.',
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),

            const SizedBox(height: 28),

            // Feature comparison
            Text('What you unlock', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            ..._proFeatures.map((f) => _FeatureRow(icon: f.icon, title: f.title, description: f.description, color: f.color)
                .animate().fadeIn(delay: (_proFeatures.indexOf(f) * 50).ms)),

            const SizedBox(height: 28),

            // Social proof
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pro users recover 2.3× faster', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'Average recovery days drop from 4.1 → 1.8 days after unlocking failure signatures and personalized comeback protocols.',
                    style: TextStyle(fontSize: 13, color: context.textSecondary),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 28),

            if (isPro) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF10B981)),
                    SizedBox(width: 12),
                    Text('You\'re on Pro — all features unlocked.', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ] else ...[
              // Annual (highlighted)
              _PriceButton(
                label: 'Annual — \$79/year',
                sub: 'Save 27% · \$6.58/mo · Best value',
                color: const Color(0xFF6366F1),
                onTap: () => _launch(_annualUrl, context),
              ).animate().fadeIn(delay: 350.ms),
              const SizedBox(height: 10),
              _PriceButton(
                label: 'Monthly — \$9/month',
                sub: 'Cancel anytime',
                color: const Color(0xFF8B5CF6),
                filled: false,
                onTap: () => _launch(_monthlyUrl, context),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  '7-day free trial · No credit card to start',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _launch(String url, BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open payment page. Try again.')),
        );
      }
    }
  }
}

class _Feature {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _Feature({required this.icon, required this.color, required this.title, required this.description});
}

const _proFeatures = [
  _Feature(icon: Icons.psychology, color: Color(0xFF6366F1), title: 'Unlimited habits & swaps', description: 'Free plan caps at 2 habits and 1 swap.'),
  _Feature(icon: Icons.replay_circle_filled, color: Color(0xFFF59E0B), title: 'Unlimited Comeback Protocol', description: 'Free plan gives you 3 comebacks/month. Pro removes the cap.'),
  _Feature(icon: Icons.insights, color: Color(0xFF8B5CF6), title: 'Failure Signatures (v2 Playbook)', description: 'See which habit slips most, your hardest day of the week, and your avg recovery speed.'),
  _Feature(icon: Icons.bolt, color: Color(0xFF10B981), title: 'Personalized recovery protocol', description: 'Comeback micro-actions tailored to your failure style and peak energy window.'),
  _Feature(icon: Icons.notifications_active, color: Color(0xFF3B82F6), title: 'Smart nudges', description: 'Loss aversion alerts when myelination is decaying. Comeback streak protection.'),
];

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  const _FeatureRow({required this.icon, required this.color, required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(description, style: TextStyle(fontSize: 12, color: context.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceButton extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  final bool filled;
  final VoidCallback onTap;
  const _PriceButton({required this.label, required this.sub, required this.color, required this.onTap, this.filled = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: filled
          ? FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Column(
                children: [
                  Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(sub, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8))),
                ],
              ),
            )
          : OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Column(
                children: [
                  Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                  Text(sub, style: TextStyle(fontSize: 11, color: context.textSecondary)),
                ],
              ),
            ),
    );
  }
}
