import 'package:flutter/material.dart';

import '../models/doubt.dart';
import '../utils/time_format.dart';

class QueueItemCard extends StatelessWidget {
  const QueueItemCard({super.key, required this.position, required this.doubt});

  final int position;
  final Doubt doubt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: colors.primaryContainer,
              foregroundColor: colors.onPrimaryContainer,
              child: Text('$position'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doubt.studentName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    doubt.topic,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    doubt.question,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (doubt.createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Joined ${timeAgo(doubt.createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
