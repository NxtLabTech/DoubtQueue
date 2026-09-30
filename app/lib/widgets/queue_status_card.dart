import 'package:flutter/material.dart';

import '../models/doubt.dart';
import 'status_badge.dart';

class QueueStatusCard extends StatelessWidget {
  const QueueStatusCard({
    super.key,
    required this.doubt,
    required this.refreshing,
  });

  final Doubt doubt;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            if (doubt.isWaiting)
              _buildWaiting(context)
            else
              _buildOtherStatus(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        StatusBadge(status: doubt.status),
        const Spacer(),
        if (refreshing) ...[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text('Updating', style: Theme.of(context).textTheme.labelMedium),
        ],
      ],
    );
  }

  Widget _buildWaiting(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text('Your position', style: theme.textTheme.titleMedium),
        Text(
          '${doubt.position ?? '-'}',
          style: theme.textTheme.displayLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Students ahead of you: ${doubt.studentsAhead}',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        Text(
          'You are currently in the queue.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOtherStatus(BuildContext context) {
    final theme = Theme.of(context);
    final style = statusStyleFor(doubt.status);

    return Column(
      children: [
        Icon(style.icon, size: 56, color: style.accent),
        const SizedBox(height: 12),
        Text(
          _message(doubt.status),
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _message(String status) {
    switch (status) {
      case 'IN_PROGRESS':
        return "It's your turn. The mentor is ready for your doubt.";
      case 'SOLVED':
        return 'Your doubt has been solved.';
      case 'SKIPPED':
        return 'Your doubt was skipped.';
      default:
        return '';
    }
  }
}
