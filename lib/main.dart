import 'package:flutter/material.dart';

void main() {
  runApp(const PothoAlertApp());
}

class PothoAlertApp extends StatelessWidget {
  const PothoAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PothoAlert',
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
        title: const Text('PothoAlert'),
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
