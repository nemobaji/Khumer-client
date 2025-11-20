// main.dart

import 'package:flutter/material.dart';
import 'package:myapp/screens/user_info_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '경희대학교 중앙도서관',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 11, 96, 166), 
        hintColor: const Color.fromARGB(255, 217, 42, 30), 
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: false,
        ),
        textTheme: TextTheme(
          headlineMedium: TextStyle( 
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.grey[850],
          ),
          titleLarge: TextStyle( 
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.grey[800],
          ),
          bodyLarge: TextStyle( 
            fontSize: 16,
            color: Colors.grey[700],
          ),
          bodyMedium: TextStyle( 
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color.fromARGB(255, 21, 106, 175),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const UserInfoScreen(),
    );
  }
}