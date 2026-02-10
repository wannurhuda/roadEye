import 'package:flutter/material.dart';

void main() {
  runApp(const RoadEyeApp());
}

class RoadEyeApp extends StatelessWidget {
  const RoadEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoadEyeApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RoadEyeApp'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Text(
          'Week 1 - Setup Complete!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
