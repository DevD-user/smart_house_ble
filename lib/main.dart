import 'package:flutter/material.dart';

void main() {
  runApp(const SmartHouseApp());
}

class SmartHouseApp extends StatelessWidget {
  const SmartHouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            'Smart House BLE Project Initialized',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
