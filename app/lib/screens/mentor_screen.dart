import 'package:flutter/material.dart';

import '../models/doubt.dart';
import '../models/session.dart';
import '../services/api_service.dart';
import '../widgets/content_width.dart';
import '../widgets/status_badge.dart';

class MentorScreen extends StatefulWidget {
  const MentorScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> {
  final _title = TextEditingController();
  final _mentorName = TextEditingController();
  List<Session> _sessions = [];
  int? _selectedId;
  List<Doubt> _queue = [];
  Map<String, int> _stats = {};
  Doubt? _current;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run(_loadSessions);
  }

  @override
  void dispose() {
    _title.dispose();
    _mentorName.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _loading = false;
    });
  }

  Future<void> _loadSessions({int? selectId}) async {
    final sessions = await widget.api.getSessions(status: 'OPEN');
    final wanted = selectId ?? _selectedId;
    final stillOpen = sessions.any((s) => s.id == wanted);
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _selectedId = stillOpen ? wanted : null;
    });
    if (stillOpen) {
      await _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    final id = _selectedId!;
    final queue = await widget.api.getQueue(id);
    final stats = await widget.api.getStats(id);
    if (!mounted) return;
    setState(() {
      _queue = queue;
      _stats = stats;
    });
  }

  Future<void> _createSession() async {
    final title = _title.text.trim();
    final mentorName = _mentorName.text.trim();
    if (title.isEmpty || mentorName.isEmpty) {
      setState(
        () => _error = 'Enter a title and your name to create a session.',
      );
      return;
    }
    await _run(() async {
      final session = await widget.api.createSession(title, mentorName);
      _title.clear();
      _mentorName.clear();
      _current = null;
      await _loadSessions(selectId: session.id);
    });
  }

  Future<void> _selectSession(int? id) async {
    if (id == null || id == _selectedId) return;
    setState(() {
      _selectedId = id;
      _current = null;
      _queue = [];
      _stats = {};
    });
    await _run(_loadDetails);
  }

  Future<void> _takeNext() async {
    await _run(() async {
      final doubt = await widget.api.takeNext(_selectedId!);
      setState(() => _current = doubt);
      await _loadDetails();
    });
  }

  Future<void> _finishCurrent({required bool solved}) async {
    final id = _current!.id;
    await _run(() async {
      if (solved) {
        await widget.api.markSolved(id);
      } else {
        await widget.api.markSkipped(id);
      }
      setState(() => _current = null);
      await _loadDetails();
    });
  }

  Future<void> _closeSession() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close session?'),
        content: const Text('Students will not be able to join this session.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Close session'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await widget.api.closeSession(_selectedId!);
      _current = null;
      await _loadSessions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentor'),
        actions: [
          IconButton(
            onPressed: _busy ? null : () => _run(_loadSessions),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ContentWidth(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_busy) const LinearProgressIndicator(),
                  if (_error != null) _buildError(),
                  _buildCreateForm(),
                  const SizedBox(height: 16),
                  _buildSessionPicker(),
                  if (_selectedId != null) ..._buildSessionDetails(),
                ],
              ),
      ),
    );
  }

  Widget _buildError() {
    final colors = Theme.of(context).colorScheme;

    return Card(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_error!, style: TextStyle(color: colors.onErrorContainer)),
      ),
    );
  }

  Widget _buildCreateForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create a session',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mentorName,
              decoration: const InputDecoration(
                labelText: 'Mentor name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _busy ? null : _createSession,
              child: const Text('Create session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionPicker() {
    if (_sessions.isEmpty) {
      return const Text('There are no open sessions. Create one above.');
    }

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Open session',
        border: OutlineInputBorder(),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _selectedId,
          isExpanded: true,
          hint: const Text('Select a session'),
          items: [
            for (final session in _sessions)
              DropdownMenuItem(
                value: session.id,
                child: Text(
                  '${session.title} (${session.mentorName})',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: _busy ? null : _selectSession,
        ),
      ),
    );
  }

  List<Widget> _buildSessionDetails() {
    final textTheme = Theme.of(context).textTheme;

    return [
      const SizedBox(height: 16),
      _buildStats(),
      const SizedBox(height: 16),
      if (_current != null) _buildCurrentDoubt(_current!),
      FilledButton.icon(
        onPressed: _busy || _current != null || _queue.isEmpty
            ? null
            : _takeNext,
        icon: const Icon(Icons.arrow_forward),
        label: const Text('Take next'),
      ),
      const SizedBox(height: 24),
      Text('Waiting queue', style: textTheme.titleMedium),
      const SizedBox(height: 8),
      if (_queue.isEmpty) const Text('No students are waiting.'),
      for (var i = 0; i < _queue.length; i++) _buildQueueItem(i, _queue[i]),
      const SizedBox(height: 24),
      OutlinedButton(
        onPressed: _busy ? null : _closeSession,
        child: const Text('Close session'),
      ),
    ];
  }

  Widget _buildStats() {
    const labels = {
      'WAITING': 'Waiting',
      'IN_PROGRESS': 'In progress',
      'SOLVED': 'Solved',
      'SKIPPED': 'Skipped',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in labels.entries)
          Chip(label: Text('${entry.value}: ${_stats[entry.key] ?? 0}')),
      ],
    );
  }

  Widget _buildCurrentDoubt(Doubt doubt) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Current doubt',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                StatusBadge(status: doubt.status),
              ],
            ),
            const SizedBox(height: 8),
            Text('${doubt.studentName} - ${doubt.topic}'),
            const SizedBox(height: 4),
            Text(doubt.question),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton(
                  onPressed: _busy ? null : () => _finishCurrent(solved: true),
                  child: const Text('Mark solved'),
                ),
                OutlinedButton(
                  onPressed: _busy ? null : () => _finishCurrent(solved: false),
                  child: const Text('Skip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueItem(int index, Doubt doubt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(child: Text('${index + 1}')),
        title: Text('${doubt.studentName} - ${doubt.topic}'),
        subtitle: Text(doubt.question),
      ),
    );
  }
}
