import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        style.label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: style.textColor, fontWeight: FontWeight.w600),
      ),
    );
  }

  _BadgeStyle _styleFor(String status) {
    switch (status) {
      case 'WAITING':
        return _BadgeStyle(
          'Waiting',
          Colors.blueGrey,
          Colors.blueGrey.shade700,
        );
      case 'IN_PROGRESS':
        return _BadgeStyle('In progress', Colors.amber, Colors.amber.shade900);
      case 'SOLVED':
        return _BadgeStyle('Solved', Colors.green, Colors.green.shade800);
      case 'SKIPPED':
        return _BadgeStyle('Skipped', Colors.grey, Colors.grey.shade700);
      case 'CLOSED':
        return _BadgeStyle('Closed', Colors.red, Colors.red.shade800);
      default:
        return _BadgeStyle(status, Colors.grey, Colors.grey.shade700);
    }
  }
}

class _BadgeStyle {
  const _BadgeStyle(this.label, this.color, this.textColor);

  final String label;
  final Color color;
  final Color textColor;
}
