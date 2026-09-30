import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'screens/session_list_screen.dart';
import 'services/api_service.dart';

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: SessionListScreen(api: api),
    );
  }
}
