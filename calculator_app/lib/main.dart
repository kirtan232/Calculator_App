import 'package:flutter/material.dart';

/// Entry point for the Calculator State Lab app.
void main() {
  runApp(const CalculatorApp());
}

/// Root widget. Holds app-wide configuration such as the title and theme.
class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const CalculatorScreen(),
    );
  }
}

/// Placeholder screen; the display and button grid are added in a later step.
class CalculatorScreen extends StatelessWidget {
  const CalculatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: const Center(child: Text('0', style: TextStyle(fontSize: 48))),
    );
  }
}
