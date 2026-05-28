import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/neuro_provider.dart';
import '../utils/neuro_helpers.dart';
import '../theme/app_theme.dart';

const _uuid = Uuid();

class WeeklyCheckinModal extends ConsumerStatefulWidget {
  const WeeklyCheckinModal({super.key});

  @override
  ConsumerState<WeeklyCheckinModal> createState() => _WeeklyCheckinModalState();
}

class _WeeklyCheckinModalState extends ConsumerState<WeeklyCheckinModal> {
  int _consistency = 3;
  String _blocker = 'distraction';
  EnergyLevel _energy = EnergyLevel.normal;
  bool _routineChanged = false;

  void _submit() {
    final record = CheckinRecord(
      id: 'checkin-${_uuid.v4()}',
      date: getLocalDateString(DateTime.now()),
      consistency: _consistency,
      weeklyBlocker: _blocker,
      energyLevel: _energy,
      routineChanged: _routineChanged,
      recalibrationApplied: false,
    );
    ref.read(neuroProvider.notifier).submitCheckin(record);
    Navigator.pop(context, record);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Weekly Check-In', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Honest reflection builds better systems.', style: TextStyle(color: context.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _SectionTitle('How consistent were you this week?'),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(5, (i) {
                        final val = i + 1;
                        final selected = _consistency == val;
                        return GestureDetector(
                          onTap: () => setState(() => _consistency = val),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: selected ? const Color(0xFF6366F1) : context.cardBg,
                              shape: BoxShape.circle,
                              border: Border.all(color: selected ? const Color(0xFF6366F1) : context.borderColor),
                            ),
                            child: Center(
                              child: Text('$val', style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: selected ? Colors.white : null,
                              )),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 24),
                    _SectionTitle('What most blocked you this week?'),
                    const SizedBox(height: 12),
                    ...{
                      'energy': 'Low energy / fatigue',
                      'overwhelm': 'Feeling overwhelmed',
                      'distraction': 'Distraction / phone',
                      'life': 'Life events / travel',
                    }.entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _blocker = e.key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _blocker == e.key ? const Color(0xFF6366F1).withOpacity(0.1) : context.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _blocker == e.key ? const Color(0xFF6366F1) : context.borderColor),
                          ),
                          child: Text(e.value),
                        ),
                      ),
                    )),
                    const SizedBox(height: 24),
                    _SectionTitle('Energy level this week?'),
                    const SizedBox(height: 12),
                    Row(
                      children: EnergyLevel.values.map((e) {
                        final labels = {EnergyLevel.low: 'Low', EnergyLevel.normal: 'Normal', EnergyLevel.high: 'High'};
                        final selected = _energy == e;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _energy = e),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFF6366F1).withOpacity(0.1) : context.cardBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: selected ? const Color(0xFF6366F1) : context.borderColor),
                                ),
                                child: Text(labels[e]!, textAlign: TextAlign.center, style: TextStyle(fontWeight: selected ? FontWeight.bold : null)),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionTitle('Routine or environment changed?'),
                            Text('Travel, schedule, or major life shift.', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                          ],
                        )),
                        Switch(
                          value: _routineChanged,
                          onChanged: (v) => setState(() => _routineChanged = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(onPressed: _submit, child: const Text('Submit Check-In')),
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600));
}
