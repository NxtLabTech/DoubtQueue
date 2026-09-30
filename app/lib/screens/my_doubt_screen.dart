import 'dart:async';

import 'package:flutter/material.dart';

import '../models/doubt.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/content_width.dart';
import '../widgets/queue_status_card.dart';
import '../widgets/state_views.dart';

class MyDoubtScreen extends StatefulWidget {
  const MyDoubtScreen({super.key, required this.api, required this.doubt});

  final ApiService api;
  final Doubt doubt;

  @override
  State<MyDoubtScreen> createState() => _MyDoubtScreenState();
}

class _MyDoubtScreenState extends State<MyDoubtScreen> {
  late Doubt _doubt;
  Timer? _timer;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _doubt = widget.doubt;
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      final doubt = await widget.api.getDoubt(_doubt.id);
      if (!mounted) return;
      setState(() {
        _doubt = doubt;
        _error = null;
      });
      if (doubt.isFinished) {
        _timer?.cancel();
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
    if (!mounted) return;
    setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My doubt'),
        actions: [
          IconButton(
            onPressed: _refreshing ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(pagePadding),
          children: [
            QueueStatusCard(doubt: _doubt, refreshing: _refreshing),
            if (_error != null) ...[
              const SizedBox(height: itemGap),
              ErrorBanner(message: _error!, onRetry: _refresh),
            ],
            const SizedBox(height: sectionGap),
            _buildDetails(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your doubt', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('Topic', style: theme.textTheme.labelMedium),
            Text(_doubt.topic, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            Text('Question', style: theme.textTheme.labelMedium),
            Text(_doubt.question, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
