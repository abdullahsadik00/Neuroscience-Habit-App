import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/neuro_provider.dart';
import '../theme/app_theme.dart';

class AddSwapSheet extends ConsumerStatefulWidget {
  const AddSwapSheet({super.key});

  @override
  ConsumerState<AddSwapSheet> createState() => _AddSwapSheetState();
}

class _AddSwapSheetState extends ConsumerState<AddSwapSheet> {
  final _titleCtrl = TextEditingController();
  final _cueCtrl = TextEditingController();
  final _badCtrl = TextEditingController();
  final _interceptCtrl = TextEditingController();
  int _frictionLevel = 2;
  final List<TextEditingController> _frictionCtrls = [TextEditingController()];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _cueCtrl.dispose();
    _badCtrl.dispose();
    _interceptCtrl.dispose();
    for (final c in _frictionCtrls) c.dispose();
    super.dispose();
  }

  void _addFrictionStep() {
    if (_frictionCtrls.length < 5) {
      setState(() => _frictionCtrls.add(TextEditingController()));
    }
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) return;
    ref.read(neuroProvider.notifier).addNeuroSwap(
      title: _titleCtrl.text.trim(),
      cue: _cueCtrl.text.trim(),
      badResponse: _badCtrl.text.trim(),
      interceptAction: _interceptCtrl.text.trim(),
      frictionLevel: _frictionLevel,
      frictionSteps: _frictionCtrls.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, controller) => Container(
        decoration: BoxDecoration(
          color: context.bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.borderColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Add Neuro Swap', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Field(label: 'Bad Habit Name', controller: _titleCtrl, hint: 'e.g. Mindless Phone Checking'),
                    _Field(label: 'Trigger / Cue', controller: _cueCtrl, hint: 'When I feel...'),
                    _Field(label: 'Old Response', controller: _badCtrl, hint: 'I reach for my phone...'),
                    _Field(label: 'Intercept Action', controller: _interceptCtrl, hint: 'Instead I will...'),
                    const SizedBox(height: 16),
                    Text('Friction Level: $_frictionLevel/5', style: Theme.of(context).textTheme.labelLarge),
                    Slider(
                      value: _frictionLevel.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      onChanged: (v) => setState(() => _frictionLevel = v.round()),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Friction Barriers', style: Theme.of(context).textTheme.labelLarge),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _addFrictionStep,
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    ..._frictionCtrls.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: e.value,
                        decoration: InputDecoration(
                          hintText: 'Friction step ${e.key + 1}...',
                          prefixText: '${e.key + 1}. ',
                          isDense: true,
                        ),
                      ),
                    )),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(onPressed: _save, child: const Text('Add Swap')),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  const _Field({required this.label, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        TextField(controller: controller, decoration: InputDecoration(hintText: hint)),
      ],
    );
  }
}
