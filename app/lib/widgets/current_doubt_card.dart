import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/doubt.dart';
import '../theme/app_theme.dart';
import '../utils/time_format.dart';
import 'status_badge.dart';

class CurrentDoubtCard extends StatefulWidget {
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
  State<CurrentDoubtCard> createState() => _CurrentDoubtCardState();
}

class _CurrentDoubtCardState extends State<CurrentDoubtCard> {
  OverlayEntry? _toastEntry;
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    _toastEntry?.remove();
    _toastEntry = null;
    super.dispose();
  }

  String get _detailsText {
    return [
      'Name: ${widget.doubt.studentName}',
      'Email: ${widget.doubt.studentEmail}',
      'Topic: ${widget.doubt.topic}',
      'Question: ${widget.doubt.question}',
    ].join('\n');
  }

  void _showCopiedToast() {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _toastTimer?.cancel();
    _toastEntry?.remove();

    final colors = Theme.of(context).colorScheme;
    // Sit below the app bar / DEBUG ribbon so the toast stays visible.
    final top = MediaQuery.paddingOf(context).top + kToolbarHeight + 12;

    _toastEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: top,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 168),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.primary, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: colors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Details copied',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_toastEntry!);
    _toastTimer = Timer(const Duration(seconds: 3), () {
      _toastEntry?.remove();
      _toastEntry = null;
    });
  }

  Future<void> _copyDetails() async {
    await Clipboard.setData(ClipboardData(text: _detailsText));
    if (!mounted) return;
    _showCopiedToast();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final doubt = widget.doubt;

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
            _buildStatusRow(theme, doubt),
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

  Widget _buildStatusRow(ThemeData theme, Doubt doubt) {
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
          onPressed: widget.busy ? null : widget.onSolved,
          icon: const Icon(Icons.check),
          label: const Text('Mark solved'),
        ),
        OutlinedButton.icon(
          onPressed: widget.busy ? null : widget.onSkipped,
          icon: const Icon(Icons.skip_next),
          label: const Text('Skip'),
        ),
        OutlinedButton.icon(
          onPressed: _copyDetails,
          icon: const Icon(Icons.copy),
          label: const Text('Copy details'),
        ),
      ],
    );
  }
}
