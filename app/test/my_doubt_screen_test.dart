import 'package:doubtqueue/models/doubt.dart';
import 'package:doubtqueue/screens/my_doubt_screen.dart';
import 'package:doubtqueue/widgets/queue_status_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

Future<FakeBackend> pumpMyDoubt(WidgetTester tester, {int ahead = 2}) async {
  final backend = FakeBackend();
  for (var i = 0; i < ahead; i++) {
    backend.addDoubt(1, 'Student$i');
  }
  final mine = backend.addDoubt(1, 'Asha');
  final doubt = Doubt.fromJson({...mine, 'position': ahead + 1});

  await tester.pumpWidget(
    MaterialApp(
      home: MyDoubtScreen(api: backend.api, doubt: doubt),
    ),
  );
  return backend;
}

void main() {
  testWidgets('shows position, students ahead and the doubt details', (
    tester,
  ) async {
    await pumpMyDoubt(tester);

    expect(find.text('Your position'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Students ahead of you: 2'), findsOneWidget);
    expect(find.text('You are currently in the queue.'), findsOneWidget);
    expect(find.text('Waiting'), findsOneWidget);
    expect(find.text('Arrays'), findsOneWidget);
    expect(find.text('How do loops work for Asha?'), findsOneWidget);

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

  group('Accessibility & Semantics (Issue #27)', () {
    testWidgets(
      'Test 1: waiting state exposes combined semantics label, position, students ahead, and live region',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          // Plural case: position 3, 2 students ahead
          await pumpMyDoubt(tester, ahead: 2);

          var node = tester.getSemantics(find.byType(QueueStatusCard));
          expect(
            node.label,
            'Waiting. Your position is 3. 2 students ahead of you.',
          );
          expect(node.flagsCollection.isLiveRegion, isTrue);

          await tester.pumpWidget(const SizedBox());

          // Zero / singular case: position 1, 0 students ahead
          await pumpMyDoubt(tester, ahead: 0);

          node = tester.getSemantics(find.byType(QueueStatusCard));
          expect(
            node.label,
            'Waiting. Your position is 1. No students ahead of you.',
          );
          expect(node.flagsCollection.isLiveRegion, isTrue);

          await tester.pumpWidget(const SizedBox());
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets(
      'Test 2: semantics label updates after 10-second refresh when position changes',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final backend = await pumpMyDoubt(tester, ahead: 2);

          var node = tester.getSemantics(find.byType(QueueStatusCard));
          expect(
            node.label,
            'Waiting. Your position is 3. 2 students ahead of you.',
          );

          // One student ahead is solved; next refresh updates position to 2, 1 student ahead
          backend.doubts.first['status'] = 'SOLVED';
          await tester.pump(const Duration(seconds: 10));
          await tester.pump();

          node = tester.getSemantics(find.byType(QueueStatusCard));
          expect(
            node.label,
            'Waiting. Your position is 2. 1 student ahead of you.',
          );
          expect(node.flagsCollection.isLiveRegion, isTrue);

          await tester.pumpWidget(const SizedBox());
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets(
      'Test 3: semantics announcement updates when status changes from waiting to in-progress',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final backend = await pumpMyDoubt(tester, ahead: 0);

          var node = tester.getSemantics(find.byType(QueueStatusCard));
          expect(
            node.label,
            'Waiting. Your position is 1. No students ahead of you.',
          );

          backend.doubts.last['status'] = 'IN_PROGRESS';
          await tester.pump(const Duration(seconds: 10));
          await tester.pump();

          node = tester.getSemantics(find.byType(QueueStatusCard));
          expect(node.label, 'Your doubt is currently being addressed.');
          expect(node.flagsCollection.isLiveRegion, isTrue);

          await tester.pumpWidget(const SizedBox());
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets('Test 4: semantics tree exposes solved announcement', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final backend = await pumpMyDoubt(tester, ahead: 0);

        backend.doubts.last['status'] = 'SOLVED';
        await tester.pump(const Duration(seconds: 10));
        await tester.pump();

        final node = tester.getSemantics(find.byType(QueueStatusCard));
        expect(node.label, 'Your doubt has been solved.');
        expect(node.flagsCollection.isLiveRegion, isTrue);

        await tester.pumpWidget(const SizedBox());
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('Test 5: semantics tree exposes skipped announcement', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final backend = await pumpMyDoubt(tester, ahead: 0);

        backend.doubts.last['status'] = 'SKIPPED';
        await tester.pump(const Duration(seconds: 10));
        await tester.pump();

        final node = tester.getSemantics(find.byType(QueueStatusCard));
        expect(node.label, 'Your doubt was skipped.');
        expect(node.flagsCollection.isLiveRegion, isTrue);

        await tester.pumpWidget(const SizedBox());
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('Test 6: semantics tree exposes in-progress announcement', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        final backend = FakeBackend();
        final mine = backend.addDoubt(1, 'Asha');
        final doubt = Doubt.fromJson({...mine, 'status': 'IN_PROGRESS'});

        await tester.pumpWidget(
          MaterialApp(
            home: MyDoubtScreen(api: backend.api, doubt: doubt),
          ),
        );

        final node = tester.getSemantics(find.byType(QueueStatusCard));
        expect(node.label, 'Your doubt is currently being addressed.');
        expect(node.flagsCollection.isLiveRegion, isTrue);

        await tester.pumpWidget(const SizedBox());
      } finally {
        semantics.dispose();
      }
    });

    testWidgets(
      'Test 7: decorative icons do not create duplicate or separate semantics nodes',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await pumpMyDoubt(tester, ahead: 2);

          final cardNode = tester.getSemantics(find.byType(QueueStatusCard));
          expect(cardNode.childrenCount, 0);

          // Status badge icon is visually present, but excluded from semantics tree
          expect(find.byIcon(Icons.hourglass_top), findsOneWidget);

          await tester.pumpWidget(const SizedBox());
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets(
      'Test 8: status information is exposed as a single combined announcement without duplicates',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await pumpMyDoubt(tester, ahead: 2);

          // Exactly one unified status announcement node
          expect(
            find.bySemanticsLabel(
              'Waiting. Your position is 3. 2 students ahead of you.',
            ),
            findsOneWidget,
          );

          // Visual text fragments do NOT produce separate, duplicate semantics nodes
          expect(find.bySemanticsLabel('Waiting'), findsNothing);
          expect(find.bySemanticsLabel('Your position'), findsNothing);
          expect(find.bySemanticsLabel('3'), findsNothing);
          expect(
            find.bySemanticsLabel('Students ahead of you: 2'),
            findsNothing,
          );
          expect(
            find.bySemanticsLabel('You are currently in the queue.'),
            findsNothing,
          );

          // Interactive controls outside the card remain accessible
          expect(find.byTooltip('Refresh'), findsOneWidget);
          expect(
            find.widgetWithIcon(IconButton, Icons.refresh),
            findsOneWidget,
          );

          // Content outside the card retains its semantics
          expect(find.bySemanticsLabel('My doubt'), findsOneWidget);

          await tester.pumpWidget(const SizedBox());
        } finally {
          semantics.dispose();
        }
      },
    );

    testWidgets(
      'Test 9: null position waiting state announces queue presence without false position or ahead count',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          final backend = FakeBackend();
          final mine = backend.addDoubt(1, 'Asha');
          final doubt = Doubt.fromJson({...mine, 'position': null});

          await tester.pumpWidget(
            MaterialApp(
              home: MyDoubtScreen(api: backend.api, doubt: doubt),
            ),
          );

          final node = tester.getSemantics(find.byType(QueueStatusCard));
          expect(node.label, 'Waiting. You are currently in the queue.');
          expect(node.flagsCollection.isLiveRegion, isTrue);
          expect(node.label, isNot(contains('No students ahead')));
          expect(node.label, isNot(contains('-')));

          await tester.pumpWidget(const SizedBox());
        } finally {
          semantics.dispose();
        }
      },
    );
  });
}
