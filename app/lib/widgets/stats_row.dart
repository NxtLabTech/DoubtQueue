import 'package:flutter/material.dart';

import 'status_badge.dart';

class StatsRow extends StatelessWidget {
  const StatsRow({super.key, required this.stats});

  final Map<String, int> stats;

  static const _statuses = ['WAITING', 'IN_PROGRESS', 'SOLVED', 'SKIPPED'];
  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 480 ? 4 : 2;
        final cardWidth =
            (constraints.maxWidth - _gap * (columns - 1)) / columns;

        return Wrap(
          spacing: _gap,
          runSpacing: _gap,
          children: [
            for (final status in _statuses)
              SizedBox(
                width: cardWidth,
                child: _StatCard(status: status, count: stats[status] ?? 0),
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.status, required this.count});

  final String status;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = statusStyleFor(status);

    return Card(
      color: style.background,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(style.icon, size: 18, color: style.text),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    style.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: style.text,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: style.text,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
