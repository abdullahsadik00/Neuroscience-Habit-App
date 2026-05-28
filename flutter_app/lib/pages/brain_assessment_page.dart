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
      _submit();
    }
  }

  void _submit() {
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

  bool get _canProceed {
    return switch (_step) {
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
  }

  @override
  Widget build(BuildContext context) {
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
                    onTap: () { a.onSelect(); },
                  ).animate(key: ValueKey('$_step-$idx'), delay: (idx * 60).ms).fadeIn().slideX(begin: 0.1),
                );
              }),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canProceed ? _next : null,
                  child: Text(_step == _questions.length - 1 ? 'Complete Assessment' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
