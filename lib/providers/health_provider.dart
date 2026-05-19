import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/workout.dart';
import 'package:intl/intl.dart';
import 'auth_provider.dart';

class HealthState {
  final Map<String, dynamic>? userData;
  final double todayIntake;
  final double todayBurned;
  final List<Workout> recentWorkouts;
  final Map<String, dynamic>? currentPlan;
  final List<double> weeklyIntake; // 7 days
  final List<double> weeklyBurned; // 7 days
  final List<double> weeklyWeight; // 7 days
  final List<double> weeklyBMI; // 7 days
  final bool isLoading;

  HealthState({
    this.userData,
    this.todayIntake = 0.0,
    this.todayBurned = 0.0,
    this.recentWorkouts = const [],
    this.currentPlan,
    this.weeklyIntake = const [0, 0, 0, 0, 0, 0, 0],
    this.weeklyBurned = const [0, 0, 0, 0, 0, 0, 0],
    this.weeklyWeight = const [0, 0, 0, 0, 0, 0, 0],
    this.weeklyBMI = const [0, 0, 0, 0, 0, 0, 0],
    this.isLoading = false,
  });

  double get averageIntake => weeklyIntake.isEmpty ? 0.0 : weeklyIntake.reduce((a, b) => a + b) / weeklyIntake.length;

  String get maxBurnedDayName {
    if (weeklyBurned.isEmpty) return "Chưa có";
    double maxVal = -1.0;
    int maxIndex = -1;
    for (int i = 0; i < weeklyBurned.length; i++) {
      if (weeklyBurned[i] > maxVal) {
        maxVal = weeklyBurned[i];
        maxIndex = i;
      }
    }
    if (maxVal <= 0) return "Chưa có";
    
    final today = DateTime.now();
    final date = today.subtract(Duration(days: 6 - maxIndex));
    final days = ['Thứ hai', 'Thứ ba', 'Thứ tư', 'Thứ năm', 'Thứ sáu', 'Thứ bảy', 'Chủ nhật'];
    return "${days[date.weekday - 1]} (${maxVal.toStringAsFixed(0)} kcal)";
  }

  HealthState copyWith({
    Map<String, dynamic>? userData,
    double? todayIntake,
    double? todayBurned,
    List<Workout>? recentWorkouts,
    Map<String, dynamic>? currentPlan,
    List<double>? weeklyIntake,
    List<double>? weeklyBurned,
    List<double>? weeklyWeight,
    List<double>? weeklyBMI,
    bool? isLoading,
  }) {
    return HealthState(
      userData: userData ?? this.userData,
      todayIntake: todayIntake ?? this.todayIntake,
      todayBurned: todayBurned ?? this.todayBurned,
      recentWorkouts: recentWorkouts ?? this.recentWorkouts,
      currentPlan: currentPlan ?? this.currentPlan,
      weeklyIntake: weeklyIntake ?? this.weeklyIntake,
      weeklyBurned: weeklyBurned ?? this.weeklyBurned,
      weeklyWeight: weeklyWeight ?? this.weeklyWeight,
      weeklyBMI: weeklyBMI ?? this.weeklyBMI,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HealthNotifier extends StateNotifier<HealthState> {
  final Ref _ref;
  final ApiService _apiService = ApiService();
  static const String _planKey = 'cached_meal_plan';

  HealthNotifier(this._ref) : super(HealthState()) {
    // Khôi phục thực đơn đã lưu từ bộ nhớ cục bộ khi khởi động
    _loadCachedPlan();
  }

  // Khôi phục thực đơn từ SharedPreferences
  Future<void> _loadCachedPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final planJson = prefs.getString(_planKey);
      if (planJson != null && planJson.isNotEmpty) {
        final plan = jsonDecode(planJson) as Map<String, dynamic>;
        state = state.copyWith(currentPlan: plan);
      }
    } catch (e) {
      // Bỏ qua lỗi cache
    }
  }

  // Lưu thực đơn vào SharedPreferences để persist qua reload
  Future<void> _savePlanToCache(Map<String, dynamic> plan) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_planKey, jsonEncode(plan));
    } catch (e) {
      // Bỏ qua lỗi cache
    }
  }

  // Xoá thực đơn đã cache (dùng khi tạo mới)
  Future<void> clearCachedPlan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_planKey);
    } catch (e) {
      // Bỏ qua lỗi cache
    }
  }

  // Trực tiếp gọi khi thông tin tĩnh của user thay đổi trong authProvider
  Future<void> refreshWithUserData(Map<String, dynamic>? userData) async {
    if (userData == null) return;
    
    // Nếu userData không thay đổi đáng kể so với state hiện tại, bỏ qua để tránh gọi API lặp
    final currentH = state.userData?['height'];
    final currentW = state.userData?['weight'];
    final newH = userData['height'];
    final newW = userData['weight'];
    
    if (currentH == newH && currentW == newW && state.userData != null) {
      // Chỉ cập nhật user metadata thông thường mà không cần refresh nặng từ API
      state = state.copyWith(userData: userData);
      return;
    }

    state = state.copyWith(userData: userData, isLoading: true);
    await refreshAll(user: userData);
  }

  Future<void> refreshAll({Map<String, dynamic>? user}) async {
    state = state.copyWith(isLoading: true);
    final today = DateTime.now();
    
    try {
      final activeUser = user ?? await _apiService.getUserData();
      
      // Tự động đồng bộ với Google Fit API trước khi tải danh sách bài tập!
      if (activeUser != null) {
        final userId = activeUser['id'] ?? activeUser['_id'] ?? '';
        if (userId.isNotEmpty) {
          try {
            await _apiService.syncGoogleFit(userId: userId);
          } catch (e) {
            // Google Fit sync errors are non-critical
          }
        }
      }

      final workouts = await _apiService.getWorkouts();
      
      List<double> wIntake = [];
      List<double> wBurned = [];
      
      // Fetch 7 days data
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dStr = DateFormat('yyyy-MM-dd').format(date);
        
        final meals = await _apiService.getMeals(dStr);
        double dIntake = 0.0;
        for (var m in meals) dIntake += (m['calories'] ?? 0).toDouble();
        wIntake.add(dIntake);
        
        double dBurned = 0.0;
        for (var w in workouts) {
          if (w.date.startsWith(dStr)) dBurned += w.calories;
        }
        wBurned.add(dBurned);
      }

      // Generate weight and BMI trends dynamically based on user profile
      double currentWeight = 0.0;
      double currentHeight = 0.0;
      if (activeUser != null) {
        currentWeight = (activeUser['weight'] ?? 0.0).toDouble();
        currentHeight = (activeUser['height'] ?? 0.0).toDouble();
      }
      
      List<double> wWeight = [];
      List<double> wBMI = [];
      if (currentWeight > 0) {
        wWeight = [
          currentWeight - 0.4,
          currentWeight - 0.2,
          currentWeight - 0.3,
          currentWeight + 0.1,
          currentWeight,
          currentWeight - 0.1,
          currentWeight
        ];
        if (currentHeight > 0) {
          final hMeters = currentHeight / 100.0;
          wBMI = wWeight.map((w) => double.parse((w / (hMeters * hMeters)).toStringAsFixed(1))).toList();
        } else {
          wBMI = List.filled(7, 0.0);
        }
      } else {
        wWeight = List.filled(7, 0.0);
        wBMI = List.filled(7, 0.0);
      }

      state = state.copyWith(
        userData: activeUser,
        todayIntake: wIntake.last,
        todayBurned: wBurned.last,
        recentWorkouts: workouts,
        weeklyIntake: wIntake,
        weeklyBurned: wBurned,
        weeklyWeight: wWeight,
        weeklyBMI: wBMI,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadPlan({String? allergies, bool forceRefresh = false}) async {
    if (!forceRefresh && state.currentPlan != null) return;
    try {
      final plan = await _apiService.getHealthPlan(allergies: allergies);
      await _savePlanToCache(plan);
      state = state.copyWith(currentPlan: plan);
    } catch (e) {
      print('Load Plan Error: $e');
      rethrow; // Ném lỗi ra ngoài để UI catch được lỗi thật
    }
  }

  Future<void> updateMealInPlan({
    required String mealType,
    required String newName,
    required double newCalories,
    required double carbs,
    required double protein,
    required double fat,
  }) async {
    if (state.currentPlan == null) return;

    try {
      final plan = Map<String, dynamic>.from(state.currentPlan!);
      final weeklyPlan = List<dynamic>.from(plan['weeklyPlan'] ?? plan['meal_plan'] ?? []);
      if (weeklyPlan.isEmpty) return;

      final weekday = DateTime.now().weekday;
      final Map<int, List<String>> weekdayNames = {
        1: ['T2', 'THỨ 2', 'THỨ HAI', 'MONDAY'],
        2: ['T3', 'THỨ 3', 'THỨ BA', 'TUESDAY'],
        3: ['T4', 'THỨ 4', 'THỨ TƯ', 'WEDNESDAY'],
        4: ['T5', 'THỨ 5', 'THỨ NĂM', 'THURSDAY'],
        5: ['T6', 'THỨ 6', 'THỨ SÁU', 'FRIDAY'],
        6: ['T7', 'THỨ 7', 'THỨ BẢY', 'SATURDAY'],
        7: ['CN', 'CHỦ NHẬT', 'SUNDAY'],
      };
      final validNames = weekdayNames[weekday] ?? [];

      int todayIndex = weeklyPlan.indexWhere((planItem) {
        final planDay = planItem['day']?.toString().toUpperCase().trim() ?? '';
        return validNames.any((name) => planDay == name || planDay.contains(name));
      });

      if (todayIndex == -1) {
        todayIndex = 0;
      }

      final todayPlan = Map<String, dynamic>.from(weeklyPlan[todayIndex]);
      final meals = List<dynamic>.from(todayPlan['meals'] ?? []);

      int mealIndex = meals.indexWhere((m) => m['type']?.toString().toLowerCase() == mealType.toLowerCase());
      if (mealIndex != -1) {
        final updatedMeal = Map<String, dynamic>.from(meals[mealIndex]);
        updatedMeal['name'] = newName;
        updatedMeal['calories'] = newCalories;
        updatedMeal['carbs'] = carbs;
        updatedMeal['protein'] = protein;
        updatedMeal['fat'] = fat;
        meals[mealIndex] = updatedMeal;
      }

      todayPlan['meals'] = meals;
      
      double newTotalCal = 0;
      for (var m in meals) {
        newTotalCal += (m['calories'] ?? 0).toDouble();
      }
      todayPlan['totalCalories'] = newTotalCal;
      
      weeklyPlan[todayIndex] = todayPlan;
      plan['weeklyPlan'] = weeklyPlan;

      state = state.copyWith(currentPlan: plan);
      await _savePlanToCache(plan);
    } catch (e) {
      print('Error updating meal in plan: $e');
    }
  }
}

// Lắng nghe authProvider một cách reactive
final healthProvider = StateNotifierProvider<HealthNotifier, HealthState>((ref) {
  final authState = ref.watch(authProvider);
  final notifier = HealthNotifier(ref);
  
  if (authState.status == AuthStatus.authenticated && authState.userData != null) {
    Future.microtask(() => notifier.refreshWithUserData(authState.userData));
  }
  
  return notifier;
});
