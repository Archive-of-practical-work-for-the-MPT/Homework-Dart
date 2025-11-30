import 'package:flutter/material.dart';
import '/screens/welcome_screen.dart';
import 'dart:async';

void main() {
  runZonedGuarded(
    () {
      runApp(const MyApp());
    },
    (e, st) {
      print("Error catched in main thread $e");
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}
