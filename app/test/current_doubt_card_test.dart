import 'package:doubtqueue/models/doubt.dart';
import 'package:doubtqueue/widgets/current_doubt_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Doubt sampleDoubt() {
  return Doubt.fromJson({
    'id': 1,
    'session_id': 1,
    'student_name': 'Asha',
    'student_email': 'asha@example.com',
    'topic': 'Arrays',
    'question': 'How do loops work for Asha?',
    'status': 'IN_PROGRESS',
    'created_at': '2026-01-01 10:05:00',
    'started_at': '2026-01-01 10:10:00',
  });
}

Future<void> pumpCard(
  WidgetTester tester, {
  double width = 800,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CurrentDoubtCard(
          doubt: sampleDoubt(),
          busy: false,
          onSolved: () {},
          onSkipped: () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Copy details puts the four fields on the clipboard', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          final args = methodCall.arguments as Map<dynamic, dynamic>;
          copied = args['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await pumpCard(tester);

    expect(find.text('Copy details'), findsOneWidget);
    await tester.tap(find.text('Copy details'));
    await tester.pump();

    expect(
      copied,
      'Name: Asha\n'
      'Email: asha@example.com\n'
      'Topic: Arrays\n'
      'Question: How do loops work for Asha?',
    );
    expect(find.text('Details copied'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Details copied'), findsNothing);
  });

  testWidgets('Copy details fits with the other buttons at 360px', (
    tester,
  ) async {
    await pumpCard(tester, width: 360);

    expect(find.text('Copy details'), findsOneWidget);
    expect(find.text('Mark solved'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
