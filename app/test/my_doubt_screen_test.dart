import 'package:doubtqueue/models/doubt.dart';
import 'package:doubtqueue/models/session.dart';
import 'package:doubtqueue/screens/my_doubt_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Future<FakeBackend> pumpMyDoubt(
  WidgetTester tester, {
  int ahead = 2,
  Session? session,
  bool provideSession = true,
}) async {
  final backend = FakeBackend();
  for (var i = 0; i < ahead; i++) {
    backend.addDoubt(1, 'Student$i');
  }
  final mine = backend.addDoubt(1, 'Asha');
  final doubt = Doubt.fromJson({...mine, 'position': ahead + 1});
  final effectiveSession = provideSession
      ? (session ?? Session.fromJson(backend.sessions.first))
      : null;

  await tester.pumpWidget(
    MaterialApp(
      home: MyDoubtScreen(
        api: backend.api,
        doubt: doubt,
        session: effectiveSession,
      ),
    ),
  );
  return backend;
}

void main() {
  testWidgets('shows session title, mentor name, position and doubt details', (
    tester,
  ) async {
    await pumpMyDoubt(tester);

    expect(find.text('PHP Basics Doubt Session'), findsOneWidget);
    expect(find.text('Mentor: Priya'), findsOneWidget);
    expect(find.text('Your position'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Students ahead of you: 2'), findsOneWidget);
    expect(find.text('You are currently in the queue.'), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);
    expect(find.text('Arrays'), findsOneWidget);
    expect(find.text('How do loops work for Asha?'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'session title and mentor name remain visible across all doubt statuses',
    (tester) async {
      final backend = await pumpMyDoubt(tester, ahead: 0);

      // 1. WAITING status
      expect(find.text('PHP Basics Doubt Session'), findsOneWidget);
      expect(find.text('Mentor: Priya'), findsOneWidget);
      expect(find.text('Waiting'), findsOneWidget);

      // 2. IN_PROGRESS status
      backend.doubts.last['status'] = 'IN_PROGRESS';
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      expect(find.text('PHP Basics Doubt Session'), findsOneWidget);
      expect(find.text('Mentor: Priya'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);

      // 3. SOLVED status
      backend.doubts.last['status'] = 'SOLVED';
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      expect(find.text('PHP Basics Doubt Session'), findsOneWidget);
      expect(find.text('Mentor: Priya'), findsOneWidget);
      expect(find.text('Your doubt has been solved.'), findsOneWidget);

      // 4. SKIPPED status
      await tester.pumpWidget(const SizedBox());
      final backendSkipped = await pumpMyDoubt(tester, ahead: 0);
      backendSkipped.doubts.last['status'] = 'SKIPPED';
      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      expect(find.text('PHP Basics Doubt Session'), findsOneWidget);
      expect(find.text('Mentor: Priya'), findsOneWidget);
      expect(find.text('Your doubt was skipped.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('handles long session title and mentor name without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final longSession = Session.fromJson({
      'id': 1,
      'title':
          'Very Long Extended Title For Mentor Doubt Clearing Session That Wraps Across Multiple Lines',
      'mentor_name':
          'Dr. Alexander Bartholomew Montgomery Senior Teaching Fellow',
      'status': 'OPEN',
      'waiting_count': 1,
    });

    await pumpMyDoubt(tester, session: longSession);

    expect(tester.takeException(), isNull);
    expect(
      find.text(
        'Very Long Extended Title For Mentor Doubt Clearing Session That Wraps Across Multiple Lines',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Mentor: Dr. Alexander Bartholomew Montgomery Senior Teaching Fellow',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('renders gracefully when session is null', (tester) async {
    await pumpMyDoubt(tester, provideSession: false);

    expect(find.text('Your position'), findsOneWidget);
    expect(find.text('Arrays'), findsOneWidget);
    expect(find.text('PHP Basics Doubt Session'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('refreshes every 10 seconds and updates the position', (
    tester,
  ) async {
    final backend = await pumpMyDoubt(tester);

    backend.doubts.first['status'] = 'SOLVED';
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('Students ahead of you: 1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows the turn message when the mentor takes the doubt', (
    tester,
  ) async {
    final backend = await pumpMyDoubt(tester, ahead: 0);

    backend.doubts.last['status'] = 'IN_PROGRESS';
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    expect(
      find.text("It's your turn. The mentor is ready for your doubt."),
      findsOneWidget,
    );
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Your position'), findsNothing);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('solved doubts show a message and stop refreshing', (
    tester,
  ) async {
    final backend = await pumpMyDoubt(tester, ahead: 0);

    backend.doubts.last['status'] = 'SOLVED';
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    expect(find.text('Your doubt has been solved.'), findsOneWidget);
    expect(find.text('Students ahead of you: 0'), findsNothing);

    backend.failRequests = true;
    await tester.pump(const Duration(seconds: 30));
    expect(find.text('Your doubt has been solved.'), findsOneWidget);
    expect(find.text('Something went wrong'), findsNothing);
  });

  testWidgets('skipped doubts show the skipped message', (tester) async {
    final backend = await pumpMyDoubt(tester, ahead: 0);

    backend.doubts.last['status'] = 'SKIPPED';
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    expect(find.text('Your doubt was skipped.'), findsOneWidget);
    expect(find.text('Skipped'), findsOneWidget);
  });

  testWidgets('keeps the last status and shows an error when refresh fails', (
    tester,
  ) async {
    final backend = await pumpMyDoubt(tester);

    backend.failRequests = true;
    await tester.pump(const Duration(seconds: 10));
    await tester.pump();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Students ahead of you: 2'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
