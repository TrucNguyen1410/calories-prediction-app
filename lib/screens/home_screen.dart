import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/workout.dart';
import '../utils/responsive.dart';
import '../theme.dart';
import '../providers/health_provider.dart';
import 'meal_history_screen.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _quickLogController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(healthProvider.notifier).refreshAll());
  }

  @override
  void dispose() {
    _quickLogController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(healthProvider);

    if (healthState.isLoading && healthState.userData == null) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        color: AppTheme.primary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chào mừng trở lại 👋,', style: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                state.userData?['name'] ?? 'Người dùng', 
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87, letterSpacing: -0.5),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: IconButton(
                icon: const Icon(Icons.sync, color: AppTheme.primary, size: 22),
                tooltip: 'Đồng bộ dữ liệu',
                onPressed: () => ref.read(healthProvider.notifier).refreshAll(),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Stack(
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_none_outlined, size: 22, color: isDark ? const Color(0xFFF2F3F5) : Colors.black), 
                    onPressed: () {},
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                ],
              ),
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
        double aspectRatio = Responsive.isMobile(context) ? 2.2 : 1.7;
        
        if (Responsive.isMobile(context)) {
          return Column(
            children: [
              _buildBMICard(state),
              const SizedBox(height: 20),
              _buildCaloriesCard(state),
              const SizedBox(height: 20),
              _buildAICard(),
              const SizedBox(height: 24),
              _buildLineChartCard(state),
              const SizedBox(height: 20),
              _buildBarChartCard(state),
            ],
          );
        }

        return Column(
          children: [
            // Row 1: Bento Overview Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: aspectRatio,
              children: [
                _buildBMICard(state),
                _buildCaloriesCard(state),
                _buildAICard(),
              ],
            ),
            const SizedBox(height: 24),
            // Row 2: fl_chart Visual Dashboards
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildLineChartCard(state)),
                const SizedBox(width: 20),
                Expanded(flex: 1, child: _buildBarChartCard(state)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildBMICard(HealthState state) {
    double bmi = 0.0;
    String status = "Chưa có";
    Color statusColor = Colors.grey;
    double height = 0.0;
    double weight = 0.0;

    if (state.userData != null) {
      height = (state.userData!['height'] ?? 0).toDouble();
      weight = (state.userData!['weight'] ?? 0).toDouble();
      if (height > 0 && weight > 0) {
        bmi = weight / ((height / 100) * (height / 100));
        if (bmi < 18.5) {
          status = "Gầy";
          statusColor = Colors.blue;
        } else if (bmi >= 18.5 && bmi <= 22.9) {
          status = "Bình thường";
          statusColor = Colors.green;
        } else if (bmi >= 23.0 && bmi <= 24.9) {
          status = "Thừa cân nhẹ";
          statusColor = Colors.orangeAccent;
        } else if (bmi >= 25.0 && bmi <= 29.9) {
          status = "Béo phì độ 1";
          statusColor = Colors.redAccent;
        } else {
          status = "Béo phì độ 2";
          statusColor = const Color(0xFFB71C1C);
        }
      }
    }

    return _buildBentoCard(
      title: 'Chỉ số BMI của bạn',
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      bmi > 0 ? bmi.toStringAsFixed(1) : '--',
                      style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: -1),
                    ),
                    const SizedBox(width: 4),
                    Text('kg/m²', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF949BA4) : Colors.black38, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  height > 0 && weight > 0 ? '${height.toInt()} cm • ${weight.toStringAsFixed(0)} kg' : 'Chưa thiết lập chiều cao/cân nặng',
                  style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF949BA4) : Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildBMIGauge(bmi, statusColor),
        ],
      ),
    );
  }

  Widget _buildBMIGauge(double bmi, Color statusColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double percent = bmi > 0 ? ((bmi - 15.0) / (35.0 - 15.0)).clamp(0.0, 1.0) : 0.0;

    return Container(
      height: 90,
      width: 24,
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background/gradient track of the gauge
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Container(
              width: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: bmi > 0
                    ? const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.blue,          // Gầy
                          Colors.green,         // Bình thường
                          Colors.orangeAccent,  // Thừa cân nhẹ
                          Colors.redAccent,     // Béo phì độ 1
                          Color(0xFFB71C1C),    // Béo phì độ 2
                        ],
                        stops: [
                          0.0,
                          0.175,
                          0.4,
                          0.5,
                          0.75,
                        ],
                      )
                    : null,
                color: bmi > 0 ? null : (isDark ? const Color(0xFF35373C) : Colors.grey[200]),
              ),
            ),
          ),
          // Current status indicator dot
          if (bmi > 0)
            Positioned(
              bottom: (percent * 90) - 8,
              left: 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2B2D31) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: statusColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCaloriesCard(HealthState state) {
    const double calTarget = 2000.0;
    final intake = state.todayIntake;
    final progress = (intake / calTarget).clamp(0.0, 1.0);

    return _buildBentoCard(
      title: 'Calories hôm nay',
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Text(
                  '${intake.toInt()}',
                  key: ValueKey<int>(intake.toInt()),
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.orangeAccent, letterSpacing: -1),
                ),
              ),
              const SizedBox(width: 4),
              Text('kcal', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF949BA4) : Colors.black38, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF35373C) : Colors.grey[200],
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mục tiêu: ${calTarget.toInt()} kcal',
            style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF949BA4) : Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAICard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildBentoCard(
      title: 'Nhật ký dinh dưỡng AI',
      color: Theme.of(context).cardColor,
      action: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MealHistoryScreen()),
          );
          ref.read(healthProvider.notifier).refreshAll();
        },
        child: const Text(
          'Lịch sử 🕒',
          style: TextStyle(
            color: AppTheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _quickLogController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Bạn vừa ăn gì hôm nay?',
              hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt_outlined, color: Colors.purpleAccent, size: 18),
                    onPressed: _handleImagePick,
                  ),
                  IconButton(
                    icon: const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 18),
                    onPressed: () => _handleQuickLog(_quickLogController.text),
                  ),
                ],
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1F22) : Colors.purple.withOpacity(0.04),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            onSubmitted: (val) => _handleQuickLog(val),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildQuickTag('🥣 Ăn sáng'),
                const SizedBox(width: 8),
                _buildQuickTag('🥗 Ăn trưa'),
                const SizedBox(width: 8),
                _buildQuickTag('🥩 Ăn tối'),
                const SizedBox(width: 8),
                _buildQuickTag('🍎 Ăn nhẹ'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTag(String tagText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        final currentText = _quickLogController.text;
        if (currentText.isEmpty) {
          _quickLogController.text = tagText;
        } else {
          _quickLogController.text = currentText.endsWith(' ') ? '$currentText$tagText' : '$currentText $tagText';
        }
        _quickLogController.selection = TextSelection.fromPosition(
          TextPosition(offset: _quickLogController.text.length),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1F22) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF35373C) : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Text(
          tagText,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFDBDEE1) : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildLineChartCard(HealthState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildBentoCard(
      title: 'Xu hướng calo nạp vào (7 ngày qua)',
      color: Theme.of(context).cardColor,
      child: Container(
        height: 220,
        padding: const EdgeInsets.only(top: 24, right: 16, bottom: 8),
        child: state.weeklyIntake.isEmpty 
          ? const Center(child: Text('Chưa có dữ liệu đồ thị', style: TextStyle(color: Colors.grey, fontSize: 12)))
          : LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(color: isDark ? const Color(0xFF35373C) : Colors.grey.withOpacity(0.08), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (val, meta) {
                    if (val % 1 != 0 || val < 0 || val >= 7) return const SizedBox();
                    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(days[val.toInt()], style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF949BA4) : Colors.grey, fontWeight: FontWeight.bold)),
                    );
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
                gradient: const LinearGradient(colors: [Colors.orangeAccent, Colors.deepOrange]),
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true, 
                  gradient: LinearGradient(
                    colors: [Colors.orangeAccent.withOpacity(0.2), Colors.deepOrange.withOpacity(0.01)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarChartCard(HealthState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _buildBentoCard(
      title: 'Nạp vs Đốt (kcal)',
      color: Theme.of(context).cardColor,
      child: Container(
        height: 220,
        padding: const EdgeInsets.only(top: 24, bottom: 8),
        child: (state.weeklyIntake.isEmpty || state.weeklyBurned.isEmpty)
          ? const Center(child: Text('Chưa có dữ liệu', style: TextStyle(color: Colors.grey, fontSize: 12)))
          : BarChart(
          BarChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (val, meta) {
                    if (val % 1 != 0 || val < 0 || val >= 7) return const SizedBox();
                    final days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(days[val.toInt()], style: TextStyle(fontSize: 9, color: isDark ? const Color(0xFF949BA4) : Colors.grey, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: state.weeklyIntake.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value, 
                    color: Colors.orangeAccent, 
                    width: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  BarChartRodData(
                    toY: state.weeklyBurned[e.key], 
                    color: Colors.blueAccent, 
                    width: 6,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _handleQuickLog(String text) async {
    if (text.isEmpty) return;
    _analyzeData(text: text);
  }

  Future<void> _handleImagePick() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tải ảnh phân tích dinh dưỡng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.camera_alt_outlined, color: AppTheme.primary),
              ),
              title: const Text('Chụp ảnh mới', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_outlined, color: Colors.purple),
              ),
              title: const Text('Chọn ảnh từ thư viện', style: TextStyle(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        _analyzeData(
          imageBytes: bytes,
          fileName: file.name,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải ảnh: $e')),
      );
    }
  }

  Future<void> _analyzeData({String? text, List<int>? imageBytes, String? fileName}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Xác nhận dinh dưỡng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (data['imageUrl'] != null && data['imageUrl'].toString().startsWith('data:')) ...[
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(
                    base64Decode(data['imageUrl'].toString().split(',')[1]),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary, 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: () async {
                  await _apiService.addMeal(
                    name: data['foodName'],
                    calories: (data['estimatedCalories'] as num).toDouble(),
                    mealType: 'AI Log',
                    date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    imageUrl: data['imageUrl'],
                  );
                  Navigator.pop(context);
                  ref.read(healthProvider.notifier).refreshAll();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã lưu món ăn thành công! 🎉'), backgroundColor: Colors.green),
                  );
                },
                child: const Text('Lưu vào nhật ký', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildBentoCard({
    required String title,
    required Widget child,
    required Color color,
    Widget? action,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                  ),
                  if (action != null) action,
                ],
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentWorkoutsHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Lịch sử tập luyện', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87)),
        TextButton(
          onPressed: () {}, 
          child: const Row(
            children: [
              Text('Xem tất cả', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkoutList(List<Workout> workouts) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (workouts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: const Center(
          child: Text('Chưa có lịch sử tập luyện hôm nay', style: TextStyle(color: Colors.grey, fontSize: 13)),
        ),
      );
    }
    
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1), 
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.directions_run_outlined, color: Colors.blueAccent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.activityType, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87)),
                    const SizedBox(height: 4),
                    Text(
                      '${w.duration.toInt()} phút • ${DateFormat('dd/MM HH:mm').format(DateTime.parse(w.date))}', 
                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF949BA4) : Colors.grey[500], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '+${w.calories.toStringAsFixed(0)} kcal', 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}