import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'screens/session_list_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(DoubtQueueApp(api: ApiService(http.Client())));
}

class DoubtQueueApp extends StatelessWidget {
  const DoubtQueueApp({super.key, required this.api});

  final ApiService api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DoubtQueue',
      theme: buildAppTheme(),
      home: SessionListScreen(api: api),
    );
  }
}
