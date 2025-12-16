import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/workout.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userData;
  
  double _bmi = 0.0;
  String _bmiStatus = "Chưa có";
  double _todayIntake = 0.0; // calories consumed today

  // primaryColor removed: header uses white AppBar per design

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadRecentWorkouts();
    _loadTodayIntake();
    _syncMealsFromServer(); // Sync meals from server on init
  }

  List<Workout> _recentWorkouts = [];
  bool _isLoadingWorkouts = true;
  double _todayCalories = 0.0;

  Future<void> _loadRecentWorkouts() async {
    final data = await _apiService.getWorkouts();
    setState(() {
      _recentWorkouts = data;
      _isLoadingWorkouts = false;
      _calculateTodayCalories();
    });
  }

  void _calculateTodayCalories() {
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    
    double total = 0.0;
    for (final w in _recentWorkouts) {
      try {
        final wDate = DateTime.parse(w.date);
        final wDateStr = "${wDate.year}-${wDate.month.toString().padLeft(2, '0')}-${wDate.day.toString().padLeft(2, '0')}";
        if (wDateStr == todayStr) {
          total += w.calories;
        }
      } catch (_) {
        // Skip invalid dates
      }
    }
    
    setState(() {
      _todayCalories = total;
    });
  }

  // Load today's intake from SharedPreferences
  Future<void> _loadTodayIntake() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      final userData = await _apiService.getUserData();
      final userId = userData?['id'] ?? userData?['_id'] ?? 'anonymous';
      // Use userId in the key so each account has separate meal history
      final key = 'meals_${userId}_$dateStr';
      final raw = prefs.getString(key);
      double total = 0.0;
      if (raw != null) {
        final List<dynamic> list = json.decode(raw);
        for (final item in list) {
          try {
            total += (item['calories'] ?? 0).toDouble();
          } catch (_) {}
        }
      }
      setState(() {
        _todayIntake = total;
      });
    } catch (e) {
      // ignore errors
    }
  }

  // Sync meals from server to local storage
  Future<void> _syncMealsFromServer() async {
    try {
      final today = DateTime.now();
      final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      final userData = await _apiService.getUserData();
      final userId = userData?['id'] ?? userData?['_id'] ?? 'anonymous';
      
      final serverMeals = await _apiService.getMeals(dateStr);
      
      final prefs = await SharedPreferences.getInstance();
      final key = 'meals_${userId}_$dateStr';
      
      if (serverMeals.isNotEmpty) {
        // Convert server meals to local format
        final localMeals = serverMeals.map((m) => {
          'name': m['name'],
          'calories': m['calories'],
          'mealType': m['mealType'],
          'timestamp': m['timestamp'] ?? m['createdAt'] ?? DateTime.now().toIso8601String(),
        }).toList();
        await prefs.setString(key, json.encode(localMeals));
      } else {
        // If no meals on server, clear local storage for this user/date
        await prefs.remove(key);
      }
      await _loadTodayIntake();
    } catch (e) {
      print('Error syncing meals from server: $e');
    }
  }

  // Add a meal entry for today and update stored list
  Future<void> _addMealEntry({required String name, required double calories, required String mealType}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final userData = await _apiService.getUserData();
    final userId = userData?['id'] ?? userData?['_id'] ?? 'anonymous';
    final key = 'meals_${userId}_$dateStr';
    
    final raw = prefs.getString(key);
    List<dynamic> list = [];
    if (raw != null) {
      try {
        list = json.decode(raw);
      } catch (_) {
        list = [];
      }
    }

    final entry = {
      'name': name,
      'calories': calories,
      'mealType': mealType,
      'timestamp': DateTime.now().toIso8601String(),
    };
    list.add(entry);
    await prefs.setString(key, json.encode(list));
    
    // Also sync to server
    try {
      await _apiService.addMeal(
        name: name,
        calories: calories,
        mealType: mealType,
        date: dateStr,
      );
    } catch (e) {
      print('Error saving meal to server: $e');
      // Still save locally even if server fails
    }
    
    await _loadTodayIntake();
  }

  // Show dialog to add meal (matches BMI dialog styling)
  void _showAddMealDialog() {
    final nameController = TextEditingController();
    final caloriesController = TextEditingController();
    String selectedMeal = 'Sáng';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.restaurant, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Ghi lại bữa ăn',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tên món ăn',
                    hintText: 'Ví dụ: Phở bò',
                    labelStyle: const TextStyle(color: Colors.blue),
                    prefixIcon: Icon(Icons.food_bank, color: Colors.blue.withOpacity(0.6)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: caloriesController,
                  decoration: InputDecoration(
                    labelText: 'Số calo',
                    hintText: 'Ví dụ: 450',
                    labelStyle: const TextStyle(color: Colors.blue),
                    prefixIcon: Icon(Icons.local_fire_department, color: Colors.blue.withOpacity(0.6)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMeal,
                  items: ['Sáng', 'Trưa', 'Tối', 'Snack']
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) selectedMeal = v;
                  },
                  decoration: InputDecoration(
                    labelText: 'Bữa ăn',
                    labelStyle: const TextStyle(color: Colors.blue),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final cal = double.tryParse(caloriesController.text.trim());
                if (name.isEmpty || cal == null || cal <= 0) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng nhập tên món và số calo hợp lệ')),
                  );
                  return;
                }
                try {
                  await _addMealEntry(name: name, calories: cal, mealType: selectedMeal);
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('✅ Đã lưu: $name • ${cal.toStringAsFixed(0)} kcal'), backgroundColor: Colors.green, duration: const Duration(seconds: 1)),
                    );
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Lưu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  // Tải dữ liệu user (height, weight)
  Future<void> _loadData() async {
    final data = await _apiService.getUserData();
    if (data != null) {
      setState(() {
        _userData = data;
        _calculateBmi();
      });
    }
  }
  
  // Tính toán BMI
  void _calculateBmi() {
    if (_userData == null) return;
    
    double height = (_userData!['height'] ?? 0).toDouble(); // (cm)
    double weight = (_userData!['weight'] ?? 0).toDouble(); // (kg)
    
    if (height > 0 && weight > 0) {
      double heightInMeters = height / 100;
      double bmiValue = weight / (heightInMeters * heightInMeters);
      
      setState(() {
        _bmi = bmiValue;
        // Phân loại BMI
        if (bmiValue < 18.5) {
          _bmiStatus = "Thiếu cân";
        } else if (bmiValue < 24.9) {
          _bmiStatus = "Cân đối";
        } else if (bmiValue < 29.9) {
          _bmiStatus = "Thừa cân";
        } else if (bmiValue < 34.9) {
          _bmiStatus = "Béo phì";
        } else {
          _bmiStatus = "Béo phì nguy hiểm";
        }
      });
    } else {
      setState(() {
        _bmi = 0.0;
        _bmiStatus = "Chưa có";
      });
    }
  }

  // Hiển thị hộp thoại nhập BMI
  void _showBmiDialog() {
    if (_userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng đăng nhập để dùng tính năng này')),
      );
      return;
    }
    
    final heightController = TextEditingController(text: (_userData!['height'] ?? 0) > 0 ? _userData!['height'].toString() : '');
    final weightController = TextEditingController(text: (_userData!['weight'] ?? 0) > 0 ? _userData!['weight'].toString() : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.accessibility_new, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Cập nhật chỉ số',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chiều cao
                TextField(
                  controller: heightController,
                  decoration: InputDecoration(
                    labelText: 'Chiều cao (cm)',
                    hintText: 'Ví dụ: 165',
                    labelStyle: const TextStyle(color: Colors.blue),
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.height, color: Colors.blue.withOpacity(0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                // Cân nặng
                TextField(
                  controller: weightController,
                  decoration: InputDecoration(
                    labelText: 'Cân nặng (kg)',
                    hintText: 'Ví dụ: 68',
                    labelStyle: const TextStyle(color: Colors.blue),
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.scale, color: Colors.blue.withOpacity(0.6)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.grey, fontSize: 14)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              ),
              onPressed: () async {
                // Lấy giá trị
                double? height = double.tryParse(heightController.text);
                double? weight = double.tryParse(weightController.text);
                
                if (height == null || weight == null || height <= 0 || weight <= 0) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Vui lòng nhập chiều cao và cân nặng hợp lệ')),
                   );
                   return;
                }

                try {
                  // Gọi API cập nhật
                  await _apiService.updateUserProfile(
                    userId: _userData!['id'],
                    height: height,
                    weight: weight,
                  );
                  
                  // Tải lại dữ liệu mới
                  await _loadData(); 
                  
                  if (mounted) {
                    Navigator.pop(context); // Đóng dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✅ Cập nhật chỉ số thành công!'),
                        duration: const Duration(seconds: 1),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }

                } catch (e) {
                   if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
                      );
                   }
                }
              },
              child: const Text('Lưu', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // --- Header và Thanh tìm kiếm (Giữ nguyên) ---
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            pinned: true,
            centerTitle: true,
            title: const Text(
              'Bảng tổng quan tập luyện',
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            toolbarHeight: 70,
          ),

          // (Removed horizontal task menu: members / appointments / vaccination / reminders)
          
          // --- BẢNG TỔNG QUAN với nền gradient xanh (giống trang Dự đoán) ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE8F6FF), Color(0xFFDFF3FF), Color(0xFFBEE7FF)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: LayoutBuilder(builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildDashboardCard(
                        width: cardWidth,
                        height: 110,
                        icon: Icons.local_fire_department,
                        title: 'Calorie intake & burn',
                        value: '${_todayCalories.toStringAsFixed(1)} kcal đã đốt',
                        iconColor: Colors.orange,
                      ),
                      _buildDashboardCard(
                        width: cardWidth,
                        height: 110,
                        icon: Icons.accessibility_new,
                        title: 'BMI',
                        value: '$_bmiStatus (${_bmi.toStringAsFixed(1)})',
                        iconColor: Colors.blue,
                        onTap: _showBmiDialog,
                      ),
                      _buildDashboardCard(
                        width: cardWidth,
                        height: 110,
                        icon: Icons.restaurant_menu,
                        title: 'Calo đã nạp',
                        value: '${_todayIntake.toStringAsFixed(0)} kcal đã nạp',
                        iconColor: Colors.green,
                        onTap: _showAddMealDialog,
                      ),
                      _buildDashboardCard(
                        width: cardWidth,
                        height: 110,
                        icon: Icons.calendar_today,
                        title: 'Lịch tập dự kiến',
                        value: '5 buổi / tuần',
                        iconColor: Colors.purple,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),

          // --- Lịch sử tập luyện gần đây ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text(
                'Lịch sử tập luyện gần đây',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _isLoadingWorkouts
                  ? const Center(child: CircularProgressIndicator())
                  : _recentWorkouts.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: Center(child: Text('Chưa có lịch sử tập luyện')),
                        )
                      : Column(
                          children: _recentWorkouts.take(5).map((w) {
                            final date = _formatDate(w.date);
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.fitness_center, color: Colors.blueAccent),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('${w.activityType} • ${w.duration} phút',
                                              style: const TextStyle(fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 6),
                                          Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    Text('${w.calories.toStringAsFixed(1)} kcal',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  // (Hàm _buildScrollableMenuButton giữ nguyên)
  // (Removed _buildScrollableMenuButton and related MenuButton widget)
  
  // WIDGET MỚI: Card cho Bảng tổng quan
  Widget _buildDashboardCard({
    double? width,
    double? height,
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final card = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
        child: Container(
        width: width,
        height: height,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // Make cards slightly translucent so gradient from parent shows through
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return width != null || height != null
        ? SizedBox(width: width, height: height, child: card)
        : card;
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return iso;
    }
  }
}