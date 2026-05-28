import 'package:flutter/material.dart';
import '../utils/stats_helpers.dart';
import '../theme/app_theme.dart';

class WeeklyGrid extends StatelessWidget {
  final List<WeekDay> days;
  const WeeklyGrid({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) => _DayDot(day: d)).toList(),
    );
  }
}

class _DayDot extends StatelessWidget {
  final WeekDay day;
  const _DayDot({required this.day});

  @override
  Widget build(BuildContext context) {
    Color dotColor;
    if (day.completed) {
      dotColor = const Color(0xFF10B981);
    } else if (day.comeback) {
      dotColor = const Color(0xFFF59E0B);
    } else if (day.missed) {
      dotColor = const Color(0xFFEF4444).withOpacity(0.6);
    } else if (day.isFuture) {
      dotColor = context.borderColor;
    } else {
      dotColor = context.borderColor;
    }

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            border: day.isToday
                ? Border.all(color: const Color(0xFF6366F1), width: 2)
                : null,
          ),
          child: day.completed
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : day.comeback
                  ? const Icon(Icons.arrow_back, color: Colors.white, size: 12)
                  : null,
        ),
        const SizedBox(height: 4),
        Text(
          day.label,
          style: TextStyle(
            fontSize: 10,
            color: day.isToday ? const Color(0xFF6366F1) : context.textSecondary,
            fontWeight: day.isToday ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
