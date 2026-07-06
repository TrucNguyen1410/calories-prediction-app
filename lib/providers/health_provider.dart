import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/workout.dart';
import '../utils/health_calc.dart';
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
  final double todayWaterMl; // lượng nước đã uống hôm nay (ml)
  final double todaySteps; // số bước hôm nay (đồng bộ từ Google Fit)
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
    this.todayWaterMl = 0.0,
    this.todaySteps = 0.0,
    this.isLoading = false,
  });

  double get averageIntake => weeklyIntake.isEmpty ? 0.0 : weeklyIntake.reduce((a, b) => a + b) / weeklyIntake.length;

  /// Mục tiêu calo nạp hằng ngày cá nhân hóa (TDEE). Trả 2000 nếu thiếu dữ liệu.
  double get dailyCalorieTarget {
    if (userData == null) return 2000.0;
    final weight = (userData!['weight'] ?? 0).toDouble();
    final height = (userData!['height'] ?? 0).toDouble();
    final gender = userData!['gender']?.toString() ?? 'Nam';
    final goal = userData!['goal']?.toString() ?? 'maintain';
    final activity = userData!['activityLevel']?.toString() ?? 'light';
    final age = HealthCalc.ageFromDob(userData!['dob']);
    final target = HealthCalc.dailyCalorieTarget(
      weightKg: weight,
      heightCm: height,
      age: age,
      gender: gender,
      goal: goal,
      activityLevel: activity,
    );
    return target ?? 2000.0;
  }

  /// Mục tiêu nước uống hằng ngày (ml).
  double get waterTargetMl {
    final weight = (userData?['weight'] ?? 0).toDouble();
    return HealthCalc.dailyWaterTargetMl(weight);
  }

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
    double? todayWaterMl,
    double? todaySteps,
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
      todayWaterMl: todayWaterMl ?? this.todayWaterMl,
      todaySteps: todaySteps ?? this.todaySteps,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HealthNotifier extends StateNotifier<HealthState> {
  final Ref _ref;
  final ApiService _apiService = ApiService();
  static const String _planKey = 'cached_meal_plan';
  bool _isRefreshing = false; // chống gọi refreshAll chồng chéo gây giật giao diện

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

    state = state.copyWith(userData: userData);
    await refreshAll(user: userData);
  }

  Future<void> refreshAll({Map<String, dynamic>? user}) async {
    // Nếu đang có một lần làm mới chạy dở, bỏ qua lần gọi mới để tránh giật/đồng bộ trùng
    if (_isRefreshing) return;
    _isRefreshing = true;
    state = state.copyWith(isLoading: true);
    final today = DateTime.now();

    try {
      final activeUser = user ?? await _apiService.getUserData();
      
      // Tự động đồng bộ với Google Fit API trước khi tải danh sách bài tập!
      double syncedSteps = state.todaySteps; // giữ giá trị cũ nếu đồng bộ lỗi
      if (activeUser != null) {
        final userId = activeUser['id'] ?? activeUser['_id'] ?? '';
        if (userId.isNotEmpty) {
          try {
            final res = await _apiService.syncGoogleFit(userId: userId);
            syncedSteps = ((res['data']?['steps']) ?? syncedSteps).toDouble();
          } catch (e) {
            // Lỗi đồng bộ Google Fit không nghiêm trọng (token hết hạn / chưa liên kết)
          }
        }
      }

      final workouts = await _apiService.getWorkouts();
      final allMeals = await _apiService.getMeals();
      final waterToday = await _apiService.getWaterToday();
      
      List<double> wIntake = [];
      List<double> wBurned = [];
      
      // Fetch 7 days data
      for (int i = 6; i >= 0; i--) {
        final date = today.subtract(Duration(days: i));
        final dStr = DateFormat('yyyy-MM-dd').format(date);
        
        final dayMeals = allMeals.where((m) => m['date'] == dStr).toList();
        double dIntake = 0.0;
        for (var m in dayMeals) {
          dIntake += (m['calories'] ?? 0).toDouble();
        }
        wIntake.add(dIntake);
        
        double dBurned = 0.0;
        for (var w in workouts) {
          if (w.date.startsWith(dStr)) dBurned += w.calories;
        }
        wBurned.add(dBurned);
      }

      // Dựng xu hướng cân nặng & BMI 7 ngày từ DỮ LIỆU ĐO THẬT (HealthMetric).
      double currentWeight = 0.0;
      double currentHeight = 0.0;
      if (activeUser != null) {
        currentWeight = (activeUser['weight'] ?? 0.0).toDouble();
        currentHeight = (activeUser['height'] ?? 0.0).toDouble();
      }

      final weightRecords = await _apiService.getWeightRecords();
      final hMeters = currentHeight > 0 ? currentHeight / 100.0 : 0.0;

      // Lấy cân nặng đo được gần nhất tính đến từng ngày (carry-forward nếu ngày đó không đo)
      List<double> wWeight = [];
      List<double> wBMI = [];
      for (int i = 6; i >= 0; i--) {
        final dayEnd = DateTime(today.year, today.month, today.day)
            .subtract(Duration(days: i))
            .add(const Duration(days: 1));

        double? weightOnDay;
        for (final r in weightRecords) {
          final dt = DateTime.tryParse(r['date']?.toString() ?? '');
          if (dt != null && dt.isBefore(dayEnd)) {
            // records sắp xếp mới→cũ, phần tử đầu thỏa điều kiện là gần nhất
            weightOnDay = (r['weight'] ?? 0).toDouble();
            break;
          }
        }
        // Nếu chưa có bản ghi nào trước ngày đó, dùng cân nặng hiện tại của hồ sơ
        final w = weightOnDay ?? currentWeight;
        wWeight.add(w);
        if (hMeters > 0 && w > 0) {
          wBMI.add(double.parse((w / (hMeters * hMeters)).toStringAsFixed(1)));
        } else {
          wBMI.add(0.0);
        }
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
        todayWaterMl: waterToday,
        todaySteps: syncedSteps,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Ghi thêm nước uống (ml) và cập nhật tổng trong ngày.
  Future<void> addWater(int amountMl) async {
    final result = await _apiService.addWater(amountMl);
    if (result['success'] == true) {
      state = state.copyWith(todayWaterMl: (result['totalMl'] ?? state.todayWaterMl).toDouble());
    }
  }

  /// Hoàn tác lần ghi nước gần nhất trong ngày.
  Future<void> undoWater() async {
    final total = await _apiService.undoLastWater();
    state = state.copyWith(todayWaterMl: total);
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
    String? servingSize,
    String? dayName,
  }) async {
    if (state.currentPlan == null) return;

    try {
      final plan = Map<String, dynamic>.from(state.currentPlan!);
      final weeklyPlan = List<dynamic>.from(plan['weeklyPlan'] ?? plan['meal_plan'] ?? []);
      if (weeklyPlan.isEmpty) return;

      int targetIndex = -1;
      if (dayName != null) {
        final searchName = dayName.toUpperCase().trim();
        targetIndex = weeklyPlan.indexWhere((planItem) {
          final planDay = planItem['day']?.toString().toUpperCase().trim() ?? '';
          return planDay == searchName || planDay.contains(searchName);
        });
      }

      if (targetIndex == -1) {
        // Fallback to today
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
        targetIndex = weeklyPlan.indexWhere((planItem) {
          final planDay = planItem['day']?.toString().toUpperCase().trim() ?? '';
          return validNames.any((name) => planDay == name || planDay.contains(name));
        });
      }

      if (targetIndex == -1) {
        targetIndex = 0;
      }

      final todayPlan = Map<String, dynamic>.from(weeklyPlan[targetIndex]);
      final meals = List<dynamic>.from(todayPlan['meals'] ?? []);

      int mealIndex = meals.indexWhere((m) => m['type']?.toString().toLowerCase() == mealType.toLowerCase());
      if (mealIndex != -1) {
        final updatedMeal = Map<String, dynamic>.from(meals[mealIndex]);
        updatedMeal['name'] = newName;
        updatedMeal['calories'] = newCalories;
        updatedMeal['carbs'] = carbs;
        updatedMeal['protein'] = protein;
        updatedMeal['fat'] = fat;
        if (servingSize != null) {
          updatedMeal['servingSize'] = servingSize;
        }
        meals[mealIndex] = updatedMeal;
      }

      todayPlan['meals'] = meals;
      
      double newTotalCal = 0;
      for (var m in meals) {
        newTotalCal += (m['calories'] ?? 0).toDouble();
      }
      todayPlan['totalCalories'] = newTotalCal;
      
      weeklyPlan[targetIndex] = todayPlan;
      plan['weeklyPlan'] = weeklyPlan;

      state = state.copyWith(currentPlan: plan);
      await _savePlanToCache(plan);
    } catch (e) {
      print('Error updating meal in plan: $e');
    }
  }

  Future<void> removeMealFromPlan({
    required String mealType,
    String? dayName,
  }) async {
    if (state.currentPlan == null) return;

    try {
      final plan = Map<String, dynamic>.from(state.currentPlan!);
      final weeklyPlan = List<dynamic>.from(plan['weeklyPlan'] ?? plan['meal_plan'] ?? []);
      if (weeklyPlan.isEmpty) return;

      int targetIndex = -1;
      if (dayName != null) {
        final searchName = dayName.toUpperCase().trim();
        targetIndex = weeklyPlan.indexWhere((planItem) {
          final planDay = planItem['day']?.toString().toUpperCase().trim() ?? '';
          return planDay == searchName || planDay.contains(searchName);
        });
      }

      if (targetIndex == -1) {
        // Fallback to today
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
        targetIndex = weeklyPlan.indexWhere((planItem) {
          final planDay = planItem['day']?.toString().toUpperCase().trim() ?? '';
          return validNames.any((name) => planDay == name || planDay.contains(name));
        });
      }

      if (targetIndex == -1) {
        targetIndex = 0;
      }

      final todayPlan = Map<String, dynamic>.from(weeklyPlan[targetIndex]);
      final meals = List<dynamic>.from(todayPlan['meals'] ?? []);

      int mealIndex = meals.indexWhere((m) => m['type']?.toString().toLowerCase() == mealType.toLowerCase());
      if (mealIndex != -1) {
        final updatedMeal = Map<String, dynamic>.from(meals[mealIndex]);
        updatedMeal['name'] = 'Chưa chọn món';
        updatedMeal['calories'] = 0;
        updatedMeal['carbs'] = 0;
        updatedMeal['protein'] = 0;
        updatedMeal['fat'] = 0;
        meals[mealIndex] = updatedMeal;
      }

      todayPlan['meals'] = meals;
      
      double newTotalCal = 0;
      for (var m in meals) {
        newTotalCal += (m['calories'] ?? 0).toDouble();
      }
      todayPlan['totalCalories'] = newTotalCal;
      
      weeklyPlan[targetIndex] = todayPlan;
      plan['weeklyPlan'] = weeklyPlan;

      state = state.copyWith(currentPlan: plan);
      await _savePlanToCache(plan);
    } catch (e) {
      print('Error removing meal from plan: $e');
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
