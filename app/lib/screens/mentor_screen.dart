import 'package:flutter/material.dart';

import '../models/doubt.dart';
import '../models/session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/content_width.dart';
import '../widgets/create_session_card.dart';
import '../widgets/current_doubt_card.dart';
import '../widgets/queue_item_card.dart';
import '../widgets/section_header.dart';
import '../widgets/state_views.dart';
import '../widgets/stats_row.dart';
import '../widgets/status_badge.dart';

class MentorScreen extends StatefulWidget {
  const MentorScreen({super.key, required this.api});

  final ApiService api;

  @override
  State<MentorScreen> createState() => _MentorScreenState();
}

class _MentorScreenState extends State<MentorScreen> {
  List<Session> _sessions = [];
  int? _selectedId;
  List<Doubt> _queue = [];
  Map<String, int> _stats = {};
  Doubt? _current;
  bool _loading = true;
  bool _busy = false;
  String? _loadError;
  String? _actionError;
  String? _notice;

  Session? get _selected {
    for (final session in _sessions) {
      if (session.id == _selectedId) return session;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadFirstTime();
  }

  Future<void> _loadFirstTime() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      await _loadSessions();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadError = e.message);
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _actionError = null;
      _notice = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionError = e.message);
    }
    if (!mounted) return;
    setState(() => _busy = false);
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

  Future<void> _createSession(String title, String mentorName) async {
    final session = await widget.api.createSession(title, mentorName);
    setState(() => _current = null);
    await _loadSessions(selectId: session.id);
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

  Future<void> _markSolved() async {
    final id = _current!.id;
    await _run(() async {
      await widget.api.markSolved(id);
      setState(() => _current = null);
      await _loadDetails();
    });
  }

  Future<void> _skip() async {
    final confirmed = await confirmAction(
      context,
      title: 'Skip this doubt?',
      message: 'The student will see that their doubt was skipped.',
      confirmLabel: 'Skip doubt',
    );
    if (!confirmed) return;

    final id = _current!.id;
    await _run(() async {
      await widget.api.markSkipped(id);
      setState(() => _current = null);
      await _loadDetails();
    });
  }

  Future<void> _closeSession() async {
    final confirmed = await confirmAction(
      context,
      title: 'Close this session?',
      message: 'Students will not be able to join it any more.',
      confirmLabel: 'Close session',
    );
    if (!confirmed) return;

    final title = _selected?.title ?? 'Session';
    await _run(() async {
      await widget.api.closeSession(_selectedId!);
      _current = null;
      await _loadSessions();
      setState(() => _notice = '$title was closed.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mentor dashboard'),
        actions: [
          IconButton(
            onPressed: _busy || _loading ? null : () => _run(_loadSessions),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ContentWidth(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const LoadingView(message: 'Loading dashboard...');
    }
    if (_loadError != null) {
      return ErrorView(message: _loadError!, onRetry: _loadFirstTime);
    }

    return ListView(
      padding: const EdgeInsets.all(pagePadding),
      children: [
        Text(
          'Start a session, then take students from the queue one by one.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: itemGap),
        SizedBox(
          height: 4,
          child: _busy ? const LinearProgressIndicator() : null,
        ),
        if (_actionError != null) ...[
          ErrorBanner(message: _actionError!),
          const SizedBox(height: itemGap),
        ],
        if (_notice != null) ...[
          SuccessBanner(message: _notice!),
          const SizedBox(height: itemGap),
        ],
        const SizedBox(height: itemGap),
        CreateSessionCard(onCreate: _createSession),
        const SizedBox(height: sectionGap),
        ..._buildSessionSection(),
      ],
    );
  }

  List<Widget> _buildSessionSection() {
    final session = _selected;

    return [
      const SectionHeader(title: 'Session'),
      const SizedBox(height: itemGap),
      if (_sessions.isEmpty)
        const Card(
          child: EmptyView(
            icon: Icons.event_busy,
            title: 'No open sessions',
            message: 'Start a session above to open a queue for students.',
          ),
        )
      else
        _buildSessionPicker(),
      if (session != null) ...[
        const SizedBox(height: sectionGap),
        const SectionHeader(title: 'Statistics'),
        const SizedBox(height: itemGap),
        StatsRow(stats: _stats),
        const SizedBox(height: sectionGap),
        ..._buildCurrentSection(),
        const SizedBox(height: sectionGap),
        ..._buildQueueSection(),
      ],
    ];
  }

  Widget _buildSessionPicker() {
    final session = _selected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Open session'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedId,
                  isExpanded: true,
                  hint: const Text('Select a session'),
                  items: [
                    for (final item in _sessions)
                      DropdownMenuItem(
                        value: item.id,
                        child: Text(
                          '${item.title} (${item.mentorName})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: _busy ? null : _selectSession,
                ),
              ),
            ),
            if (session != null) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  StatusBadge(status: session.status),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _closeSession,
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Close session'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCurrentSection() {
    final current = _current;

    return [
      const SectionHeader(title: 'Current doubt'),
      const SizedBox(height: itemGap),
      if (current != null)
        CurrentDoubtCard(
          doubt: current,
          busy: _busy,
          onSolved: _markSolved,
          onSkipped: _skip,
        )
      else
        _buildNoCurrentDoubt(),
    ];
  }

  Widget _buildNoCurrentDoubt() {
    final hasWaiting = _queue.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const EmptyView(
              icon: Icons.support_agent,
              title: 'No doubt is currently in progress.',
              message: 'Take the next student when you are ready.',
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy || !hasWaiting ? null : _takeNext,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Take next student'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildQueueSection() {
    return [
      SectionHeader(
        title: 'Waiting queue',
        subtitle: '${_queue.length} waiting',
        trailing: TextButton.icon(
          onPressed: _busy ? null : () => _run(_loadDetails),
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
      ),
      const SizedBox(height: itemGap),
      if (_queue.isEmpty)
        const Card(
          child: EmptyView(
            icon: Icons.groups_outlined,
            title: 'No students are waiting.',
            message: 'New questions will appear here when students join.',
          ),
        )
      else
        for (var i = 0; i < _queue.length; i++) ...[
          QueueItemCard(position: i + 1, doubt: _queue[i]),
          const SizedBox(height: itemGap),
        ],
    ];
  }
}
