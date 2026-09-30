import 'package:flutter/material.dart';

import '../models/session.dart';
import '../services/api_service.dart';
import '../widgets/content_width.dart';
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

  String? _required(String? value) {
    return value == null || value.trim().isEmpty
        ? 'This field is required'
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Join Queue')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              widget.session.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text('Mentor: ${widget.session.mentorName}'),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _email,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _topic,
                    decoration: const InputDecoration(
                      labelText: 'Topic',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: _required,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _question,
                    decoration: const InputDecoration(
                      labelText: 'Question',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: 6,
                    validator: _required,
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: colors.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Joining...' : 'Join Queue'),
            ),
          ],
        ),
      ),
    );
  }
}
