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
  final bool isLoading;

  HealthState({
    this.userData,
    this.todayIntake = 0.0,
    this.todayBurned = 0.0,
    this.recentWorkouts = const [],
    this.currentPlan,
    this.weeklyIntake = const [0, 0, 0, 0, 0, 0, 0],
    this.weeklyBurned = const [0, 0, 0, 0, 0, 0, 0],
    this.isLoading = false,
  });

  HealthState copyWith({
    Map<String, dynamic>? userData,
    double? todayIntake,
    double? todayBurned,
    List<Workout>? recentWorkouts,
    Map<String, dynamic>? currentPlan,
    List<double>? weeklyIntake,
    List<double>? weeklyBurned,
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

      state = state.copyWith(
        userData: activeUser,
        todayIntake: wIntake.last,
        todayBurned: wBurned.last,
        recentWorkouts: workouts,
        weeklyIntake: wIntake,
        weeklyBurned: wBurned,
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
