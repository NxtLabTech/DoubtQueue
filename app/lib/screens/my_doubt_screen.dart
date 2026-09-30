import 'dart:async';

import 'package:flutter/material.dart';

import '../models/doubt.dart';
import '../services/api_service.dart';
import '../widgets/content_width.dart';
import '../widgets/status_badge.dart';

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
  }

  String get _statusText {
    switch (_doubt.status) {
      case 'WAITING':
        return 'You are number ${_doubt.position} in the queue.';
      case 'IN_PROGRESS':
        return 'The mentor is looking at your doubt now.';
      case 'SOLVED':
        return 'Your doubt was solved.';
      case 'SKIPPED':
        return 'The mentor skipped your doubt. You can join the queue again.';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Doubt'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBadge(status: _doubt.status),
                    const SizedBox(height: 12),
                    Text(_statusText, style: textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            Text('Your question', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(_doubt.topic, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(_doubt.question),
          ],
        ),
      ),
    );
  }
}
