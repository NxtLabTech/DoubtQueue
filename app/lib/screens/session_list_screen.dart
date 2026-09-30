import 'package:flutter/material.dart';

import '../models/session.dart';
import '../services/api_service.dart';
import '../widgets/content_width.dart';
import 'join_queue_screen.dart';
import 'mentor_screen.dart';

class SessionListScreen extends StatefulWidget {
  const SessionListScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends State<SessionListScreen> {
  List<Session> _sessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final sessions = await widget.api.getSessions(status: 'OPEN');
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _error = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _openJoin(Session session) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => JoinQueueScreen(api: widget.api, session: session),
      ),
    );
    _load();
  }

  Future<void> _openMentor() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => MentorScreen(api: widget.api)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DoubtQueue'),
        actions: [
          TextButton.icon(
            onPressed: _openMentor,
            icon: const Icon(Icons.school_outlined),
            label: const Text('Mentor'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ContentWidth(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Open sessions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          if (_error != null) _ErrorMessage(message: _error!, onRetry: _load),
          if (_error == null && _sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text('There are no open sessions right now.'),
            ),
          for (final session in _sessions)
            _SessionCard(session: session, onJoin: () => _openJoin(session)),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.onJoin});

  final Session session;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(session.title, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Mentor: ${session.mentorName}'),
            Text('${session.waitingCount} waiting'),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onJoin,
                child: const Text('Join Queue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: TextStyle(color: colors.onErrorContainer)),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
