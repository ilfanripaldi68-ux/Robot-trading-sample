import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text("Robot Trading Sample")),
        body: const Center(
          child: Text(
            "Hello, ini aplikasi trading bot 🚀",
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
