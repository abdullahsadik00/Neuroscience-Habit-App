import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/neuro_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class BrainAssessmentPage extends ConsumerStatefulWidget {
  const BrainAssessmentPage({super.key});

  @override
  ConsumerState<BrainAssessmentPage> createState() => _BrainAssessmentPageState();
}

class _BrainAssessmentPageState extends ConsumerState<BrainAssessmentPage> {
  int _step = 0;
  bool _showReveal = false;

  FailureStyle? _failureStyle;
  PeakEnergyWindow? _peakEnergy;
  RecoverySpeed? _recoverySpeed;
  PrimaryBlocker? _primaryBlocker;
  SelfTalkPattern? _selfTalk;
  MotivationSource? _motivation;
  AccountabilityStyle? _accountability;
  CoreDriver? _coreDriver;

  void _next() {
    if (_step < _questions.length - 1) {
      setState(() => _step++);
    } else {
      // Show reveal before committing to state/routing
      setState(() => _showReveal = true);
    }
  }

  // Called after the user reads their profile and taps "Continue"
  void _confirm() {
    if (_failureStyle == null ||
        _peakEnergy == null ||
        _recoverySpeed == null ||
        _primaryBlocker == null ||
        _selfTalk == null ||
        _motivation == null ||
        _accountability == null ||
        _coreDriver == null) return;

    ref.read(neuroProvider.notifier).setBrainProfile(NeuroBrainProfile(
      failureStyle: _failureStyle!,
      peakEnergyWindow: _peakEnergy!,
      recoverySpeed: _recoverySpeed!,
      primaryBlocker: _primaryBlocker!,
      selfTalkPattern: _selfTalk!,
      motivationSource: _motivation!,
      accountabilityStyle: _accountability!,
      coreDriver: _coreDriver!,
      completedAt: DateTime.now().toIso8601String(),
    ));
    // Router transitions automatically when brainProfile becomes non-null
  }

  late final _questions = [
    _Question(
      question: 'When you fail to follow through on a goal, what usually happens?',
      answers: [
        _Answer('I do it perfectly or not at all', () => setState(() => _failureStyle = FailureStyle.perfectionist)),
        _Answer('I avoid it until it feels impossible', () => setState(() => _failureStyle = FailureStyle.avoider)),
        _Answer('I overthink and never start', () => setState(() => _failureStyle = FailureStyle.analyst)),
        _Answer('I just drift — no clear reason', () => setState(() => _failureStyle = FailureStyle.drifter)),
      ],
    ),
    _Question(
      question: 'When do you feel mentally sharpest?',
      answers: [
        _Answer('Morning (before 12pm)', () => setState(() => _peakEnergy = PeakEnergyWindow.morning)),
        _Answer('Afternoon (12pm–5pm)', () => setState(() => _peakEnergy = PeakEnergyWindow.afternoon)),
        _Answer('Evening (after 5pm)', () => setState(() => _peakEnergy = PeakEnergyWindow.evening)),
        _Answer('It varies day to day', () => setState(() => _peakEnergy = PeakEnergyWindow.variable)),
      ],
    ),
    _Question(
      question: 'After a bad week, how quickly do you bounce back?',
      answers: [
        _Answer('Within a day or two', () => setState(() => _recoverySpeed = RecoverySpeed.fast)),
        _Answer('About a week', () => setState(() => _recoverySpeed = RecoverySpeed.medium)),
        _Answer('Several weeks or more', () => setState(() => _recoverySpeed = RecoverySpeed.slow)),
        _Answer('It changes a lot', () => setState(() => _recoverySpeed = RecoverySpeed.variable)),
      ],
    ),
    _Question(
      question: 'What most often stops your habits from sticking?',
      answers: [
        _Answer('Low energy or fatigue', () => setState(() => _primaryBlocker = PrimaryBlocker.energy)),
        _Answer('Feeling overwhelmed', () => setState(() => _primaryBlocker = PrimaryBlocker.overwhelm)),
        _Answer('Distraction or phone use', () => setState(() => _primaryBlocker = PrimaryBlocker.distraction)),
        _Answer('Life events, travel, stress', () => setState(() => _primaryBlocker = PrimaryBlocker.life)),
      ],
    ),
    _Question(
      question: 'When you miss a habit, what goes through your head?',
      answers: [
        _Answer('"I always fail at this"', () => setState(() => _selfTalk = SelfTalkPattern.selfCritical)),
        _Answer('I avoid thinking about it', () => setState(() => _selfTalk = SelfTalkPattern.avoidant)),
        _Answer('I analyze what went wrong', () => setState(() => _selfTalk = SelfTalkPattern.rational)),
        _Answer('"What\'s the point anyway?"', () => setState(() => _selfTalk = SelfTalkPattern.hopeless)),
      ],
    ),
    _Question(
      question: 'What drives you to build better habits?',
      answers: [
        _Answer('Becoming a specific type of person', () => setState(() => _motivation = MotivationSource.identity)),
        _Answer('Achieving a specific outcome', () => setState(() => _motivation = MotivationSource.outcome)),
        _Answer('Enjoying the process itself', () => setState(() => _motivation = MotivationSource.process)),
        _Answer('Avoiding negative consequences', () => setState(() => _motivation = MotivationSource.survival)),
      ],
    ),
    _Question(
      question: 'What keeps you most accountable?',
      answers: [
        _Answer('Tracking streaks and data', () => setState(() => _accountability = AccountabilityStyle.tracking)),
        _Answer('Someone checking in on me', () => setState(() => _accountability = AccountabilityStyle.external)),
        _Answer('Good systems and reminders', () => setState(() => _accountability = AccountabilityStyle.systems)),
        _Answer('Honestly, nothing works long-term', () => setState(() => _accountability = AccountabilityStyle.none)),
      ],
    ),
    _Question(
      question: 'At your core, why do you want better habits?',
      answers: [
        _Answer('To feel better day-to-day', () => setState(() => _coreDriver = CoreDriver.feelBetter)),
        _Answer('To perform at a higher level', () => setState(() => _coreDriver = CoreDriver.performBetter)),
        _Answer('To become a specific person', () => setState(() => _coreDriver = CoreDriver.becomeSomeone)),
        _Answer("I'm barely keeping it together", () => setState(() => _coreDriver = CoreDriver.survive)),
      ],
    ),
  ];

  bool get _canProceed => switch (_step) {
        0 => _failureStyle != null,
        1 => _peakEnergy != null,
        2 => _recoverySpeed != null,
        3 => _primaryBlocker != null,
        4 => _selfTalk != null,
        5 => _motivation != null,
        6 => _accountability != null,
        7 => _coreDriver != null,
        _ => false,
      };

  @override
  Widget build(BuildContext context) {
    if (_showReveal) {
      return _RevealPage(
        failureStyle: _failureStyle!,
        peakEnergy: _peakEnergy!,
        primaryBlocker: _primaryBlocker!,
        recoverySpeed: _recoverySpeed!,
        coreDriver: _coreDriver!,
        onContinue: _confirm,
      );
    }

    final q = _questions[_step];
    final progress = (_step + 1) / _questions.length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Brain Assessment', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.textSecondary)),
                  const Spacer(),
                  Text('${_step + 1}/${_questions.length}', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.textSecondary)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: context.borderColor,
                  color: const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(height: 40),
              Text(
                q.question,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, height: 1.4),
              ).animate(key: ValueKey(_step)).fadeIn().slideX(begin: 0.05),
              const SizedBox(height: 32),
              ...q.answers.asMap().entries.map((e) {
                final idx = e.key;
                final a = e.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AnswerButton(
                    label: a.label,
                    onTap: a.onSelect,
                  ).animate(key: ValueKey('$_step-$idx'), delay: (idx * 60).ms).fadeIn().slideX(begin: 0.1),
                );
              }),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed ? _next : null,
                  child: Text(_step == _questions.length - 1 ? 'See my Brain Profile' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reveal screen shown after all 8 answers — before committing to state
// ─────────────────────────────────────────────────────────────────────────────

class _RevealPage extends StatelessWidget {
  final FailureStyle failureStyle;
  final PeakEnergyWindow peakEnergy;
  final PrimaryBlocker primaryBlocker;
  final RecoverySpeed recoverySpeed;
  final CoreDriver coreDriver;
  final VoidCallback onContinue;

  const _RevealPage({
    required this.failureStyle,
    required this.peakEnergy,
    required this.primaryBlocker,
    required this.recoverySpeed,
    required this.coreDriver,
    required this.onContinue,
  });

  static const _archetypeNames = {
    'perfectionist-feelBetter': 'The Exhausted Achiever',
    'perfectionist-performBetter': 'The Precision Driver',
    'perfectionist-becomeSomeone': 'The Identity Builder',
    'perfectionist-survive': 'The Cornered Perfectionist',
    'avoider-feelBetter': 'The Comfort Seeker',
    'avoider-performBetter': 'The Quiet Competitor',
    'avoider-becomeSomeone': 'The Reluctant Transformer',
    'avoider-survive': 'The Minimal Risk-Taker',
    'analyst-feelBetter': 'The Thoughtful Healer',
    'analyst-performBetter': 'The Systems Optimizer',
    'analyst-becomeSomeone': 'The Deliberate Builder',
    'analyst-survive': 'The Calculated Survivor',
    'drifter-feelBetter': 'The Restless Dreamer',
    'drifter-performBetter': 'The Inconsistent Sprinter',
    'drifter-becomeSomeone': 'The Aspiring Self',
    'drifter-survive': 'The Day-to-Day Navigator',
  };

  static const _archetypeDescriptions = {
    'perfectionist-feelBetter': 'You hold yourself to a high standard but pay for it in exhaustion. Your recovery protocol focuses on self-compassion over self-discipline.',
    'perfectionist-performBetter': 'You want precision results. You succeed when you have clear metrics and fail when things feel fuzzy. Your protocol is built around specificity.',
    'perfectionist-becomeSomeone': 'Identity is your fuel. You\'re not building habits — you\'re building a person. Missing a day feels like a betrayal of who you\'re becoming.',
    'perfectionist-survive': 'You\'re under pressure and holding the bar high anyway. Your recovery protocol reduces friction before anything else.',
    'avoider-feelBetter': 'Comfort is your compass. You avoid discomfort so well that you sometimes avoid the habits you actually want. Your protocol removes the activation energy.',
    'avoider-performBetter': 'You have the talent but your effort is inconsistent. Your protocol surfaces small wins quickly to build momentum.',
    'avoider-becomeSomeone': 'You have a clear vision of who you want to be. The gap between that vision and today\'s action is where you get stuck.',
    'avoider-survive': 'You operate with minimum viable effort by necessity. Your protocol is built for low-energy days, not ideal conditions.',
    'analyst-feelBetter': 'You think your way through everything, including your feelings. Your protocol uses data and patterns to bypass the analysis paralysis.',
    'analyst-performBetter': 'You are a systems thinker. Once you have the right framework, you execute well. Your protocol is about finding the right frame first.',
    'analyst-becomeSomeone': 'You have a rich internal model of who you want to be. Your challenge is converting that model into daily action.',
    'analyst-survive': 'You analyze threats carefully and act only when necessary. Your protocol is built for pragmatic, low-overhead execution.',
    'drifter-feelBetter': 'You move with energy and emotion. When you feel good, you\'re unstoppable. Your protocol anchors habits to emotional states, not rigid schedules.',
    'drifter-performBetter': 'You sprint hard and then disappear. Your protocol introduces small daily minimums that keep the pathway warm between sprints.',
    'drifter-becomeSomeone': 'You can see a better version of yourself clearly. The drift is between who you are and who you\'re becoming. Your protocol bridges that gap daily.',
    'drifter-survive': 'You\'re navigating day-to-day without a clear anchor. Your protocol gives you three habits you can do in any circumstance.',
  };

  String get _archetype => _archetypeNames['${failureStyle.name}-${coreDriver.name}'] ?? 'The Recovery Builder';
  String get _description => _archetypeDescriptions['${failureStyle.name}-${coreDriver.name}'] ?? 'Your protocol is personalized to your patterns.';

  String get _failureLabel => switch (failureStyle) {
        FailureStyle.perfectionist => 'Perfectionist',
        FailureStyle.avoider => 'Avoider',
        FailureStyle.analyst => 'Analyst',
        FailureStyle.drifter => 'Drifter',
      };

  List<String> get _insights => [
        switch (peakEnergy) {
          PeakEnergyWindow.morning => '🌅 You\'re sharpest in the morning — your Blueprint schedules key habits before noon.',
          PeakEnergyWindow.afternoon => '☀️ You peak in the afternoon — your Blueprint front-loads easier habits early.',
          PeakEnergyWindow.evening => '🌆 You\'re sharpest in the evening — your Blueprint won\'t fight your biology.',
          PeakEnergyWindow.variable => '🔀 Your energy varies — your Blueprint builds in flexible anchors, not fixed times.',
        },
        switch (primaryBlocker) {
          PrimaryBlocker.energy => '⚡ Low energy is your main blocker — your habits are optimized for 5-minute minimum doses.',
          PrimaryBlocker.overwhelm => '🧠 Overwhelm stops you — your habits are broken into micro-steps to remove the start cost.',
          PrimaryBlocker.distraction => '📱 Distraction derails you — your habits include a friction step to break the pattern.',
          PrimaryBlocker.life => '🌊 Life disruptions hit you hardest — your Comeback Protocol activates within 24 hours of a miss.',
        },
        switch (recoverySpeed) {
          RecoverySpeed.fast => '⚡ You bounce back fast — your protocol capitalizes on that momentum window.',
          RecoverySpeed.medium => '↩ You take about a week — your protocol gives you a 3-day grace window before escalating.',
          RecoverySpeed.slow => '🐢 You recover slowly — your protocol is gentler and uses smaller re-entry actions.',
          RecoverySpeed.variable => '〰️ Your recovery varies — your protocol reads your context and adapts week to week.',
        },
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Your Brain Profile',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.textSecondary),
              ).animate().fadeIn(),
              const SizedBox(height: 24),

              // Archetype reveal
              Container(
                width: double.infinity,
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
                    const Text('You are…', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 6),
                    Text(
                      _archetype,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Failure style: $_failureLabel',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ).animate().fadeIn(delay: 350.ms),
                  ],
                ),
              ).animate().fadeIn().scale(begin: const Offset(0.97, 0.97)),

              const SizedBox(height: 20),

              // Description
              Text(
                _description,
                style: TextStyle(fontSize: 15, color: context.textSecondary, height: 1.5),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 24),

              // Personalized insights
              Text(
                'What this means for your protocol',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 12),

              ..._insights.asMap().entries.map((e) => _InsightRow(
                    text: e.value,
                    delay: 550 + e.key * 80,
                  )),

              const SizedBox(height: 32),

              // CTA
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onContinue,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue to your Blueprint', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),

              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Your Blueprint is scored against this profile',
                  style: TextStyle(fontSize: 12, color: context.textSecondary),
                ),
              ).animate().fadeIn(delay: 900.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final String text;
  final int delay;
  const _InsightRow({required this.text, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.borderColor),
        ),
        child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
      ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.05),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Question {
  final String question;
  final List<_Answer> answers;
  const _Question({required this.question, required this.answers});
}

class _Answer {
  final String label;
  final VoidCallback onSelect;
  const _Answer(this.label, this.onSelect);
}

class _AnswerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AnswerButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
        ),
        child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
