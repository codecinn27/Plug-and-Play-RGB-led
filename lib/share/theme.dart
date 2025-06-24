import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: const Color(0xFFD9D9D9), // light grey background
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 16.0),
      ),
      colorScheme: ColorScheme.fromSwatch().copyWith(
        primary: Colors.deepPurple,
      ),
    );
  }
}
