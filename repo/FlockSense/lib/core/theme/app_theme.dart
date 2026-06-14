import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      brightness: Brightness.light,
      scaffoldBackgroundColor: Colors.grey.shade50,
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
  }
}
