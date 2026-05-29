import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/neuro_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _nameController = TextEditingController();
  String _role = 'Builder';
  int _step = 0;

  static const _roles = ['Builder', 'Designer', 'Athlete', 'Student', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0 && _nameController.text.trim().isEmpty) return;
    if (_step < 2) {
      setState(() => _step++);
    } else {
      ref.read(neuroProvider.notifier).setUserProfile(
        name: _nameController.text.trim(),
        role: _role,
      );
      ref.read(neuroProvider.notifier).completeOnboarding();
      // Request notification permission and schedule daily reminders
      NotificationService.requestPermission().then((_) {
        NotificationService.scheduleDailyReminder();
        NotificationService.scheduleEveningCheckin();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _buildStep(_step),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    return switch (step) {
      0 => _WelcomeStep(
          key: const ValueKey(0),
          nameController: _nameController,
          onNext: _next,
        ),
      1 => _RoleStep(
          key: const ValueKey(1),
          selected: _role,
          onSelect: (r) => setState(() => _role = r),
          onNext: _next,
        ),
      _ => _ScienceStep(key: const ValueKey(2), onNext: _next),
    };
  }
}

class _WelcomeStep extends StatelessWidget {
  final TextEditingController nameController;
  final VoidCallback onNext;
  const _WelcomeStep({super.key, required this.nameController, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.psychology, color: Color(0xFF6366F1), size: 28),
        ).animate().fadeIn().scale(),
        const SizedBox(height: 24),
        Text(
          'NeuroFlow',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
        const SizedBox(height: 8),
        Text(
          'Build habits using neuroscience — not willpower.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: context.textSecondary,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 48),
        Text(
          "What's your name?",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter your name',
            prefixIcon: Icon(Icons.person_outline),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onNext(),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onNext,
            child: const Text('Get Started'),
          ),
        ),
      ],
    );
  }
}

class _RoleStep extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onNext;
  const _RoleStep({super.key, required this.selected, required this.onSelect, required this.onNext});

  static const _roles = ['Builder', 'Designer', 'Athlete', 'Student', 'Other'];
  static const _icons = [Icons.code, Icons.brush, Icons.fitness_center, Icons.school, Icons.person];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        Text(
          'What best describes you?',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ).animate().fadeIn().slideY(begin: -0.1),
        const SizedBox(height: 8),
        Text(
          "We'll suggest habits matched to your life.",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.textSecondary),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 32),
        ...List.generate(_roles.length, (i) {
          final role = _roles[i];
          final isSelected = selected == role;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => onSelect(role),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF6366F1).withOpacity(0.15)
                      : context.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF6366F1) : context.borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(_icons[i], color: isSelected ? const Color(0xFF6366F1) : context.textSecondary),
                    const SizedBox(width: 16),
                    Text(role, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF6366F1), size: 20),
                  ],
                ),
              ),
            ),
          ).animate(delay: (i * 60).ms).fadeIn().slideX(begin: 0.1);
        }),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: onNext, child: const Text('Continue')),
        ),
      ],
    );
  }
}

class _ScienceStep extends StatelessWidget {
  final VoidCallback onNext;
  const _ScienceStep({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        Text(
          'How NeuroFlow works',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ).animate().fadeIn(),
        const SizedBox(height: 32),
        ...[
          _Science(icon: Icons.link, color: const Color(0xFF6366F1), title: 'Habit Stacking',
              body: 'Attach new habits to existing anchors. The brain builds pathways faster when linked to established ones.'),
          _Science(icon: Icons.swap_horiz, color: const Color(0xFF10B981), title: 'Neuro Swaps',
              body: 'Replace bad habits with urge surfing. Riding the craving is more durable than suppression.'),
          _Science(icon: Icons.arrow_back, color: const Color(0xFFF59E0B), title: 'Comeback Protocol',
              body: 'Missing a day is normal. The protocol gets you back with zero shame and one small action.'),
        ].asMap().entries.map((e) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: e.value.animate(delay: (e.key * 100).ms).fadeIn().slideX(begin: 0.1),
        )),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(onPressed: onNext, child: const Text("Let's begin")),
        ),
      ],
    );
  }
}

class _Science extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _Science({required this.icon, required this.color, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(body, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
