import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/workout.dart';
import '../utils/responsive.dart';
import '../theme.dart';
import '../providers/health_provider.dart';
import 'package:file_picker/file_picker.dart' as fp;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(healthProvider.notifier).refreshAll());
  }

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(healthProvider);

    if (healthState.isLoading && healthState.userData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: () => ref.read(healthProvider.notifier).refreshAll(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(healthState),
              const SizedBox(height: 32),
              _buildBentoGridPro(healthState),
              const SizedBox(height: 32),
              _buildRecentWorkoutsHeader(),
              const SizedBox(height: 16),
              _buildWorkoutList(healthState.recentWorkouts),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(HealthState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chào mừng trở lại,', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            Text(state.userData?['name'] ?? 'Người dùng', 
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.sync, color: AppTheme.primary),
              onPressed: () => ref.read(healthProvider.notifier).refreshAll(),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
              ),
              child: IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBentoGridPro(HealthState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = Responsive.isDesktop(context) ? 3 : (Responsive.isTablet(context) ? 2 : 1);
        return Column(
          children: [
            // Row 1: Summary Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: Responsive.isMobile(context) ? 2.5 : 2.0,
              children: [
                _buildSummaryCard('BMI Hiện tại', state),
                _buildSummaryCard('Calo Hôm nay', state),
                _buildAICard(),
              ],
            ),
            const SizedBox(height: 20),
            // Row 2: Charts (Full Width on Mobile, split on PC)
            if (Responsive.isMobile(context)) ...[
              _buildLineChartCard(state),
              const SizedBox(height: 20),
              _buildBarChartCard(state),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildLineChartCard(state)),
                  const SizedBox(width: 20),
                  Expanded(flex: 1, child: _buildBarChartCard(state)),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String type, HealthState state) {
    if (type == 'BMI Hiện tại') {
      double bmi = 0.0;
      String status = "Chưa có";
      if (state.userData != null) {
        double h = (state.userData!['height'] ?? 0).toDouble();
        double w = (state.userData!['weight'] ?? 0).toDouble();
        if (h > 0 && w > 0) {
          bmi = w / ((h / 100) * (h / 100));
          if (bmi < 18.5) status = "Thiếu cân";
          else if (bmi < 24.9) status = "Bình thường";
          else if (bmi < 29.9) status = "Thừa cân";
          else status = "Béo phì";
        }
      }
      return _buildBentoCard(
        title: type,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(bmi.toStringAsFixed(1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
            Text(status, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        color: Colors.white,
      );
    } else {
      return _buildBentoCard(
        title: type,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${state.todayIntake.toInt()} kcal', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange)),
            const Text('nạp vào', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        color: Colors.white,
      );
    }
  }

  Widget _buildLineChartCard(HealthState state) {
    return _buildBentoCard(
      title: 'Xu hướng Calo (7 ngày)',
      child: Container(
        height: 200,
        padding: const EdgeInsets.only(top: 20, right: 10),
        child: state.weeklyIntake.isEmpty 
          ? const Center(child: Text('Chưa có dữ liệu', style: TextStyle(fontSize: 10)))
          : LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (val, meta) {
                    if (val % 1 != 0) return const SizedBox();
                    return Text('${val.toInt() + 1}', style: const TextStyle(fontSize: 10, color: Colors.grey));
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: state.weeklyIntake.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                isCurved: true,
                color: AppTheme.primary,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(show: true, color: AppTheme.primary.withOpacity(0.1)),
              ),
            ],
          ),
        ),
      ),
      color: Colors.white,
    );
  }

  Widget _buildBarChartCard(HealthState state) {
    return _buildBentoCard(
      title: 'Nạp vs Đốt',
      child: Container(
        height: 200,
        padding: const EdgeInsets.only(top: 20),
        child: (state.weeklyIntake.isEmpty || state.weeklyBurned.isEmpty)
          ? const Center(child: Text('Chưa có dữ liệu', style: TextStyle(fontSize: 10)))
          : BarChart(
          BarChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: state.weeklyIntake.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(toY: e.value, color: Colors.orange, width: 6),
                  BarChartRodData(toY: state.weeklyBurned[e.key], color: Colors.blue, width: 6),
                ],
              );
            }).toList(),
          ),
        ),
      ),
      color: Colors.white,
    );
  }

  Widget _buildAICard() {
    final TextEditingController quickLogController = TextEditingController();

    return _buildBentoCard(
      title: 'Nhật ký AI (Text/Vision)',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: quickLogController,
            decoration: InputDecoration(
              hintText: 'Bạn ăn gì?',
              hintStyle: const TextStyle(fontSize: 10),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.purple, size: 16),
                    onPressed: _handleImagePick,
                  ),
                  IconButton(
                    icon: const Icon(Icons.auto_awesome, color: Colors.purple, size: 16),
                    onPressed: () => _handleQuickLog(quickLogController.text),
                  ),
                ],
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.purple.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            onSubmitted: (val) => _handleQuickLog(val),
          ),
        ],
      ),
      color: Colors.white,
    );
  }

  Future<void> _handleQuickLog(String text) async {
    if (text.isEmpty) return;
    _analyzeData(text: text);
  }

  Future<void> _handleImagePick() async {
    try {
      final result = await fp.FilePicker.platform.pickFiles(
        type: fp.FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        _analyzeData(
          imageBytes: result.files.single.bytes, 
          fileName: result.files.single.name
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi chọn ảnh: $e')));
    }
  }

  Future<void> _analyzeData({String? text, List<int>? imageBytes, String? fileName}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = await _apiService.analyzeFood(text: text, imageBytes: imageBytes, fileName: fileName);
      Navigator.pop(context); 
      _showConfirmationSheet(data);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _showConfirmationSheet(Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Xác nhận dinh dưỡng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildNutrientRow('Món ăn', data['foodName'] ?? 'Không rõ'),
            _buildNutrientRow('Calories', '${data['estimatedCalories']} kcal'),
            _buildNutrientRow('Protein', '${data['protein']}g'),
            _buildNutrientRow('Carbs', '${data['carbs']}g'),
            _buildNutrientRow('Fat', '${data['fat']}g'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                onPressed: () async {
                  await _apiService.addMeal(
                    name: data['foodName'],
                    calories: (data['estimatedCalories'] as num).toDouble(),
                    mealType: 'AI Log',
                    date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                  );
                  Navigator.pop(context);
                  ref.read(healthProvider.notifier).refreshAll();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã lưu vào nhật ký!')));
                },
                child: const Text('Lưu vào nhật ký', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBentoCard({required String title, required Widget child, required Color color, VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentWorkoutsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Lịch sử tập luyện', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        TextButton(onPressed: () {}, child: const Text('Xem tất cả')),
      ],
    );
  }

  Widget _buildWorkoutList(List<Workout> workouts) {
    if (workouts.isEmpty) return const Center(child: Text('Chưa có lịch sử tập luyện'));
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: workouts.length > 5 ? 5 : workouts.length,
      itemBuilder: (context, index) {
        final w = workouts[index];
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.fitness_center, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.activityType, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${w.duration} phút • ${DateFormat('dd/MM HH:mm').format(DateTime.parse(w.date))}', 
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              Text('${w.calories.toStringAsFixed(1)} kcal', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        );
      },
    );
  }
}