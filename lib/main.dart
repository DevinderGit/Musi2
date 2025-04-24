import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Musi Clone Test',
      home: Scaffold(
        appBar: AppBar(title: const Text('It Works!')),
        body: const Center(child: Text('Hello iPhone 🎶')),
      ),
    );
  }
}
