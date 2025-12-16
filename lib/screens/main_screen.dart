import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'predict_screen.dart';
import 'profile_screen.dart';

class MainScreen extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const MainScreen({Key? key, this.userData}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const StatsScreen(),
      const PredictScreen(),
      ProfileScreen(
        name: widget.userData?["name"] ?? "Người dùng",
        email: widget.userData?["email"] ?? "Không xác định",
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3A8DFF),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: "Thống kê"),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), label: "Dự đoán"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Cá nhân"),
        ],
      ),
    );
  }
}
