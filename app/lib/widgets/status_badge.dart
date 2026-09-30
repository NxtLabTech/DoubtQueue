import 'package:flutter/material.dart';

class StatusStyle {
  const StatusStyle({
    required this.label,
    required this.icon,
    required this.accent,
    required this.background,
    required this.text,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Color background;
  final Color text;
}

StatusStyle statusStyleFor(String status) {
  switch (status) {
    case 'WAITING':
      return StatusStyle(
        label: 'Waiting',
        icon: Icons.hourglass_top,
        accent: Colors.blueGrey.shade600,
        background: Colors.blueGrey.shade50,
        text: Colors.blueGrey.shade800,
      );
    case 'IN_PROGRESS':
      return StatusStyle(
        label: 'In progress',
        icon: Icons.play_circle_outline,
        accent: Colors.amber.shade800,
        background: Colors.amber.shade50,
        text: const Color(0xFF6B4500),
      );
    case 'SOLVED':
      return StatusStyle(
        label: 'Solved',
        icon: Icons.check_circle_outline,
        accent: Colors.green.shade600,
        background: Colors.green.shade50,
        text: Colors.green.shade900,
      );
    case 'SKIPPED':
      return StatusStyle(
        label: 'Skipped',
        icon: Icons.skip_next,
        accent: Colors.grey.shade600,
        background: Colors.grey.shade200,
        text: Colors.grey.shade800,
      );
    case 'CLOSED':
      return StatusStyle(
        label: 'Closed',
        icon: Icons.lock_outline,
        accent: Colors.red.shade600,
        background: Colors.red.shade50,
        text: Colors.red.shade900,
      );
    case 'OPEN':
      return StatusStyle(
        label: 'Open',
        icon: Icons.radio_button_checked,
        accent: Colors.teal.shade600,
        background: Colors.teal.shade50,
        text: Colors.teal.shade900,
      );
    default:
      return StatusStyle(
        label: status,
        icon: Icons.help_outline,
        accent: Colors.grey.shade600,
        background: Colors.grey.shade200,
        text: Colors.grey.shade800,
      );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final style = statusStyleFor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 16, color: style.text),
          const SizedBox(width: 6),
          Text(
            style.label,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(color: style.text, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
