import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/health_plan_screen.dart';
import 'theme.dart';
import 'providers/auth_provider.dart';


void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}


class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    Widget getHomeWidget() {
      switch (authState.status) {
        case AuthStatus.unknown:
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        case AuthStatus.authenticated:
          return MainScreen(userData: authState.userData);
        case AuthStatus.unauthenticated:
          return const LoginScreen();
      }
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Health Management & AI Assistant',
      theme: AppTheme.lightTheme,

      // 🧭 Màn hình mở đầu dựa trên trạng thái Auth
      home: getHomeWidget(),

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
