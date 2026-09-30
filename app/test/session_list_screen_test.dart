import 'dart:convert';

import 'package:doubtqueue/screens/session_list_screen.dart';
import 'package:doubtqueue/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('shows a card for each open session', (tester) async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode([
          {
            'id': 1,
            'title': 'PHP Basics Doubt Session',
            'mentor_name': 'Priya',
            'status': 'OPEN',
            'waiting_count': 5,
          },
          {
            'id': 2,
            'title': 'Laravel Doubt Session',
            'mentor_name': 'Kiran',
            'status': 'OPEN',
            'waiting_count': 0,
          },
        ]),
        200,
      );
    });
    final api = ApiService(client, baseUrl: 'http://test.local');

    await tester.pumpWidget(MaterialApp(home: SessionListScreen(api: api)));
    await tester.pumpAndSettle();

    expect(find.byType(Card), findsNWidgets(2));
    expect(find.text('PHP Basics Doubt Session'), findsOneWidget);
    expect(find.text('Mentor: Priya'), findsOneWidget);
    expect(find.text('5 waiting'), findsOneWidget);
    expect(find.text('Laravel Doubt Session'), findsOneWidget);
    expect(find.text('Join Queue'), findsNWidgets(2));
  });
}
