import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'Help Human';
  static const String panicButtonText = '¡PÁNICO!';
  static const String loading = 'Enviando alerta...';
  static const double panicButtonSize = 180.0;
  static const Duration pulseAnimationDuration = Duration(milliseconds: 1200);
  static const Duration snackbarDuration = Duration(seconds: 4);

  static const TextStyle titleStyle = TextStyle(
    color: Colors.white,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle panicTextStyle = TextStyle(
    color: Colors.red,
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle footerStyle = TextStyle(
    color: Colors.white70,
    fontSize: 16,
  );

  static const Color primaryRed = Colors.red;
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.red, Colors.redAccent],
  );
}
