import 'package:doubtqueue/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cases = <String, (String, IconData)>{
    'WAITING': ('Waiting', Icons.hourglass_top),
    'IN_PROGRESS': ('In progress', Icons.play_circle_outline),
    'SOLVED': ('Solved', Icons.check_circle_outline),
    'SKIPPED': ('Skipped', Icons.skip_next),
    'CLOSED': ('Closed', Icons.lock_outline),
    'OPEN': ('Open', Icons.radio_button_checked),
  };

  test('each known status has the expected label and icon', () {
    for (final entry in cases.entries) {
      final style = statusStyleFor(entry.key);
      expect(style.label, entry.value.$1, reason: entry.key);
      expect(style.icon, entry.value.$2, reason: entry.key);
    }
  });

  test('an unknown status shows its raw text and the help icon', () {
    final style = statusStyleFor('PAUSED');

    expect(style.label, 'PAUSED');
    expect(style.icon, Icons.help_outline);
  });

  testWidgets('StatusBadge renders an icon and a label together', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StatusBadge(status: 'SOLVED'),
      ),
    );

    expect(find.byType(Icon), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.text('Solved'), findsOneWidget);
    expect(find.byType(Text), findsOneWidget);
  });
}
