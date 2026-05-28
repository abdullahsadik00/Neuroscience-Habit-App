import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../providers/neuro_provider.dart';
import '../utils/neuro_helpers.dart';
import '../theme/app_theme.dart';

const _uuid = Uuid();

class RecalibrationSheet extends ConsumerStatefulWidget {
  final List<RecalibrationSuggestion> suggestions;
  const RecalibrationSheet({super.key, required this.suggestions});

  @override
  ConsumerState<RecalibrationSheet> createState() => _RecalibrationSheetState();
}

class _RecalibrationSheetState extends ConsumerState<RecalibrationSheet> {
  late final Set<String> _accepted;
  late final Set<String> _rejected;

  @override
  void initState() {
    super.initState();
    _accepted = widget.suggestions.map((s) => s.id).toSet();
    _rejected = {};
  }

  void _toggle(String id) {
    setState(() {
      if (_accepted.contains(id)) {
        _accepted.remove(id);
        _rejected.add(id);
      } else {
        _rejected.remove(id);
        _accepted.add(id);
      }
    });
  }

  void _apply() {
    final event = RecalibrationEvent(
      id: 'recal-${_uuid.v4()}',
      date: getLocalDateString(DateTime.now()),
      suggestions: widget.suggestions,
      accepted: _accepted.toList(),
      rejected: _rejected.toList(),
    );
    ref.read(neuroProvider.notifier).applyRecalibration(event);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
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
                  Text('System Recalibration', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text('Based on your check-in. Accept or reject each change.', style: TextStyle(color: context.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  ...widget.suggestions.map((s) {
                    final accepted = _accepted.contains(s.id);
                    final typeLabel = switch (s.type) {
                      SuggestionType.scaleDown => 'Scale Down',
                      SuggestionType.replace => 'Replace',
                      SuggestionType.updateMicro => 'Update Micro-Actions',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accepted ? const Color(0xFF6366F1) : context.borderColor,
                            width: accepted ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(typeLabel, style: const TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.w600)),
                                ),
                                const Spacer(),
                                Switch(value: accepted, onChanged: (_) => _toggle(s.id)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (s.habitTitle != null) Text(s.habitTitle!, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(s.reason, style: TextStyle(fontSize: 12, color: context.textSecondary)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: context.isDark ? const Color(0xFF1E2A45) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(s.fromValue, style: TextStyle(fontSize: 12, color: context.textSecondary))),
                                  const Icon(Icons.arrow_forward, size: 14),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(s.toValue, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _apply,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                    child: Text('Apply ${_accepted.length} Change${_accepted.length != 1 ? 's' : ''}'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
