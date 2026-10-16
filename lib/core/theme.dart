import 'package:flutter/material.dart';

const Color bg = Color(0xFF0B1120);
const Color panel = Color(0xFF1E293B);
const Color cyan = Color(0xFF38BDF8);
const Color green = Color(0xFF4ADEB0);
const Color amber = Color(0xFFFBBF24);
const Color red = Color(0xFFEF4444);
const Color muted = Color(0xFF94A3B8);

ThemeData get appTheme => ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: bg,
  colorScheme: ColorScheme.fromSeed(
    seedColor: cyan,
    brightness: Brightness.dark,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: panel,
    elevation: 0,
  ),
);