import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/health_provider.dart';
import '../theme.dart';

class HealthPlanScreen extends ConsumerStatefulWidget {
  const HealthPlanScreen({super.key});

  @override
  ConsumerState<HealthPlanScreen> createState() => _HealthPlanScreenState();
}

class _HealthPlanScreenState extends ConsumerState<HealthPlanScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(healthProvider.notifier).loadPlan());
  }

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(healthProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Kế hoạch Cá nhân AI', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: healthState.isLoading && healthState.currentPlan == null
          ? _buildLoading()
          : healthState.currentPlan == null
              ? _buildEmptyState()
              : _buildContent(healthState.currentPlan!),
    );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Chưa có kế hoạch nào', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Hãy yêu cầu AI tạo kế hoạch cho bạn.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref.read(healthProvider.notifier).loadPlan(),
            child: const Text('Tạo kế hoạch ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> plan) {
    final mealPlan = plan['meal_plan'] as List? ?? [];
    final exercises = plan['exercises'] as List? ?? [];

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          _buildStatusHeader(plan),
          const TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primary,
            tabs: [
              Tab(text: 'Thực đơn 7 ngày', icon: Icon(Icons.restaurant)),
              Tab(text: 'Lịch tập luyện', icon: Icon(Icons.calendar_today)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildMealList(mealPlan),
                _buildExerciseList(exercises),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(Map<String, dynamic> plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'Lời khuyên: ${plan['bmi_status'] ?? 'Bình thường'}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            plan['advice'] ?? 'Dựa trên chỉ số cơ thể của bạn, AI đã thiết kế một kế hoạch tối ưu.',
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMealList(List meals) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: AppTheme.primary.withOpacity(0.1),
                child: Text('${meal['day']}', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ),
              title: Text('Ngày ${meal['day']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Xem thực đơn chi tiết', style: TextStyle(fontSize: 12)),
              children: [
                _buildMealItem(Icons.sunny, 'Sáng', meal['breakfast']),
                _buildMealItem(Icons.wb_sunny_outlined, 'Trưa', meal['lunch']),
                _buildMealItem(Icons.apple, 'Snack', meal['snack']),
                _buildMealItem(Icons.nightlight_round, 'Tối', meal['dinner']),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealItem(IconData icon, String title, String menu) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(menu, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(List exercises) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final ex = exercises[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.green),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex['name'] ?? 'Bài tập', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${ex['sets']} hiệp x ${ex['reps']} lần • ${ex['benefit']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
