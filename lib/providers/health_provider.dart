import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/workout.dart';
import 'package:intl/intl.dart';

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
  final ApiService _apiService = ApiService();

  HealthNotifier() : super(HealthState());

  Future<void> refreshAll() async {
    state = state.copyWith(isLoading: true);
    final today = DateTime.now();
    
    try {
      final user = await _apiService.getUserData();
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
        userData: user,
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

  Future<void> loadPlan() async {
    if (state.currentPlan != null) return;
    try {
      final plan = await _apiService.getHealthPlan();
      state = state.copyWith(currentPlan: plan);
    } catch (e) {}
  }
}

final healthProvider = StateNotifierProvider<HealthNotifier, HealthState>((ref) {
  return HealthNotifier();
});
