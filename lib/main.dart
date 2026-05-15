import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/health_plan_screen.dart';
import 'theme.dart';


void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Health Management & AI Assistant',
      theme: AppTheme.lightTheme,

      // 🧭 Màn hình mở đầu
      home: const LoginScreen(),

      // 🔗 Định nghĩa route
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/main': (context) => const MainScreen(),
        '/health-plan': (context) => const HealthPlanScreen(),
      },


    );
  }
}
