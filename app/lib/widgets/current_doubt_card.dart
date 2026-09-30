import 'package:flutter/material.dart';

import '../models/doubt.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import 'status_badge.dart';

class CurrentDoubtCard extends StatelessWidget {
  const CurrentDoubtCard({
    super.key,
    required this.doubt,
    required this.busy,
    required this.onSolved,
    required this.onSkipped,
  });

  final Doubt doubt;
  final bool busy;
  final VoidCallback onSolved;
  final VoidCallback onSkipped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      color: colors.primaryContainer.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: BorderSide(color: colors.primary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow(theme),
            const SizedBox(height: 12),
            Text(
              doubt.studentName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              doubt.studentEmail,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text('Topic', style: theme.textTheme.labelMedium),
            Text(doubt.topic, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Question', style: theme.textTheme.labelMedium),
            Text(doubt.question, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 16),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(ThemeData theme) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusBadge(status: doubt.status),
        if (doubt.startedAt != null)
          Text(
            'Started ${timeAgo(doubt.startedAt)}',
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: busy ? null : onSolved,
          icon: const Icon(Icons.check),
          label: const Text('Mark solved'),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : onSkipped,
          icon: const Icon(Icons.skip_next),
          label: const Text('Skip'),
        ),
      ],
    );
  }
}
