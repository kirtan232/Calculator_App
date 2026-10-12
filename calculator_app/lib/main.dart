import 'package:flutter/material.dart';

import 'calculator_screen.dart';

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
