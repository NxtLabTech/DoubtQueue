import 'package:flutter/material.dart';

import '../models/session.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/content_width.dart';
import '../widgets/state_views.dart';
import '../widgets/status_badge.dart';
import 'my_doubt_screen.dart';

class JoinQueueScreen extends StatefulWidget {
  const JoinQueueScreen({super.key, required this.api, required this.session});

  final ApiService api;
  final Session session;

  @override
  State<JoinQueueScreen> createState() => _JoinQueueScreenState();
}

class _JoinQueueScreenState extends State<JoinQueueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _topic = TextEditingController();
  final _question = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _topic.dispose();
    _question.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final doubt = await widget.api.joinSession(
        widget.session.id,
        name: _name.text.trim(),
        email: _email.text.trim(),
        topic: _topic.text.trim(),
        question: _question.text.trim(),
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => MyDoubtScreen(api: widget.api, doubt: doubt),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    }
  }

  String? _required(String? value, String message) {
    return value == null || value.trim().isEmpty ? message : null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'Enter your email address';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join queue')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(pagePadding),
          children: [
            _SessionSummary(session: widget.session),
            const SizedBox(height: sectionGap),
            _buildFormCard(),
            if (_error != null) ...[
              const SizedBox(height: itemGap),
              ErrorBanner(message: _error!),
            ],
            const SizedBox(height: sectionGap),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_submitting ? 'Joining...' : 'Join queue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your details',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => _required(value, 'Enter your name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _topic,
                decoration: const InputDecoration(
                  labelText: 'Topic',
                  hintText: 'For example: Arrays',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => _required(value, 'Enter a topic'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _question,
                decoration: const InputDecoration(
                  labelText: 'Question',
                  hintText: 'Describe what you need help with',
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 6,
                validator: (value) => _required(value, 'Enter your question'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    session.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: session.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Mentor: ${session.mentorName}',
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
            Text(
              '${session.waitingCount} waiting',
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }
}
