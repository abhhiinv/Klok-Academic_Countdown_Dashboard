import 'package:flutter/material.dart';
import '../utils/date_utils.dart' as du;

/// A small badge showing the urgency color and label.
class UrgencyBadge extends StatelessWidget {
  final DateTime eventDate;

  const UrgencyBadge({super.key, required this.eventDate});

  @override
  Widget build(BuildContext context) {
    final color = du.getUrgencyColor(eventDate);
    final label = du.getUrgencyLabel(eventDate);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
