import 'package:flutter/material.dart';
import '../features/home/home_page.dart';
class DimensionalApp extends StatelessWidget {
  const DimensionalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dimensional',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8D56FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF080613),
      ),
      home: const HomePage(),
    );
  }
}
