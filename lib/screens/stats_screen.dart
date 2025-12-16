import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/workout.dart';
import 'meal_history_screen.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final ApiService _apiService = ApiService();
  List<Workout> _allWorkouts = [];
  Map<String, double> _consumedByDay = {};
  bool _isLoadingConsumed = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    _loadConsumedMeals();
  }

  Future<void> _loadConsumedMeals() async {
    setState(() => _isLoadingConsumed = true);
    final today = DateTime.now();
    final Map<String, double> map = {};

    // Prepare 7 days labels
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dayName = DateFormat('E').format(date);
      map[dayName] = 0;
    }

    // For each day, fetch meals and sum calories (parallel)
    final futures = <Future<void>>[];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final dayName = DateFormat('E').format(date);

      futures.add(_apiService.getMeals(dateStr).then((meals) {
        double total = 0;
        for (final m in meals) {
          try {
            final c = (m['calories'] as num?)?.toDouble() ?? 0.0;
            total += c;
          } catch (_) {}
        }
        map[dayName] = total;
      }).catchError((_) {
        map[dayName] = 0;
      }));
    }

    await Future.wait(futures);

    setState(() {
      _consumedByDay = map;
      _isLoadingConsumed = false;
    });
  }

  Future<void> _loadWorkouts() async {
    final data = await _apiService.getWorkouts();
    setState(() {
      _allWorkouts = data;
      _isLoading = false;
    });
  }

  // Tính toán calo theo ngày (7 ngày gần nhất)
  Map<String, double> _getCaloriesByDay() {
    final today = DateTime.now();
    final caloriesByDay = <String, double>{};

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      final dayName = DateFormat('E').format(date); // Mon, Tue, etc
      caloriesByDay[dayName] = 0;

      for (final w in _allWorkouts) {
        try {
          final wDate = DateTime.parse(w.date);
          final wDateStr = "${wDate.year}-${wDate.month.toString().padLeft(2, '0')}-${wDate.day.toString().padLeft(2, '0')}";
          if (wDateStr == dateStr) {
            caloriesByDay[dayName] = (caloriesByDay[dayName] ?? 0) + w.calories;
          }
        } catch (_) {}
      }
    }

    return caloriesByDay;
  }

  // Tính toán calo theo tháng (12 tháng gần nhất)
  Map<String, double> _getCaloriesByMonth() {
    final caloriesByMonth = <String, double>{};
    final now = DateTime.now();

    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final monthName = DateFormat('MMM').format(date); // Jan, Feb, etc
      caloriesByMonth[monthName] = 0;

      for (final w in _allWorkouts) {
        try {
          final wDate = DateTime.parse(w.date);
          if (wDate.year == date.year && wDate.month == date.month) {
            caloriesByMonth[monthName] = (caloriesByMonth[monthName] ?? 0) + w.calories;
          }
        } catch (_) {}
      }
    }

    return caloriesByMonth;
  }

  // Tìm ngày có calo cao nhất (7 ngày)
  double _getMaxCaloriesDay() {
    final data = _getCaloriesByDay();
    return data.isEmpty ? 0 : data.values.reduce((a, b) => a > b ? a : b);
  }

  // Tìm tháng có calo cao nhất (12 tháng)
  double _getMaxCaloriesMonth() {
    final data = _getCaloriesByMonth();
    return data.isEmpty ? 0 : data.values.reduce((a, b) => a > b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          title: const Text(
            'Thống kê calo tiêu hao',
            style: TextStyle(color: Color.fromARGB(255, 17, 16, 16), fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final caloriesByDay = _getCaloriesByDay();
    final caloriesByMonth = _getCaloriesByMonth();
    final maxDay = _getMaxCaloriesDay();
    final maxMonth = _getMaxCaloriesMonth();
    final totalCaloriesDay = caloriesByDay.values.fold(0.0, (a, b) => a + b);
    final totalCaloriesMonth = caloriesByMonth.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text('Thống kê calo tiêu hao'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            // header card to unify style with predict screen
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppTheme.mainGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.bar_chart, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Thống kê calo tiêu hao', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black))),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // --- THỐNG KÊ THEO NGÀY ---
            Text(
              'Biểu đồ calo tiêu hao theo ngày (7 ngày gần nhất)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Biểu đồ tròn
                  SizedBox(
                    height: 280,
                    child: PieChart(
                      PieChartData(
                        sections: _getPieSectionsDay(caloriesByDay),
                        centerSpaceRadius: 60,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Thông tin giữa
                  Column(
                    children: [
                      Text(
                        '${totalCaloriesDay.toStringAsFixed(0)} kcal',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng calo đã tiêu hao',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Legend
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: caloriesByDay.entries.map((entry) {
                      final index = caloriesByDay.keys.toList().indexOf(entry.key);
                      final color = _getColorForIndex(index);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${entry.key}: ${entry.value.toStringAsFixed(0)} kcal',
                            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Thông tin thêm
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox('Cao nhất', '${maxDay.toStringAsFixed(0)} kcal', Colors.blue),
                        _buildStatBox('Trung bình', '${(totalCaloriesDay / 7).toStringAsFixed(0)} kcal', Colors.green),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // --- CALORIES CONSUMED (Calo đã nạp) ---
            const SizedBox(height: 20),
            Text(
              'Calo đã nạp (7 ngày gần nhất)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
              ),
              padding: const EdgeInsets.all(16),
              child: _isLoadingConsumed
                  ? const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()))
                  : Column(
                      children: [
                        SizedBox(
                          height: 220,
                          child: PieChart(
                            PieChartData(
                              sections: _getPieSectionsDay(_consumedByDay),
                              centerSpaceRadius: 48,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_consumedByDay.values.fold(0.0, (a, b) => a + b).toStringAsFixed(0)} kcal',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const MealHistoryScreen()));
                            _loadConsumedMeals();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryDark),
                          child: const Text('Lịch sử nạp calo'),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // --- THỐNG KÊ THEO THÁNG ---
            Text(
              'Biểu đồ calo tiêu hao theo tháng (12 tháng gần nhất)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Biểu đồ tròn
                  SizedBox(
                    height: 280,
                    child: PieChart(
                      PieChartData(
                        sections: _getPieSectionsMonth(caloriesByMonth),
                        centerSpaceRadius: 60,
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Thông tin giữa
                  Column(
                    children: [
                      Text(
                        '${totalCaloriesMonth.toStringAsFixed(0)} kcal',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng calo đã tiêu hao',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Legend (3 cột)
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: caloriesByMonth.entries.map((entry) {
                      final index = caloriesByMonth.keys.toList().indexOf(entry.key);
                      final color = _getMonthColor(index);
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${entry.key}: ${entry.value.toStringAsFixed(0)} kcal',
                            style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Thông tin thêm
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatBox('Cao nhất', '${maxMonth.toStringAsFixed(0)} kcal', Colors.blue),
                        _buildStatBox('Trung bình', '${(totalCaloriesMonth / 12).toStringAsFixed(0)} kcal', Colors.green),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _getPieSectionsDay(Map<String, double> caloriesByDay) {
    final total = caloriesByDay.values.fold(0.0, (a, b) => a + b);
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey[300],
          title: 'Chưa có dữ liệu',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ];
    }

    final entries = caloriesByDay.entries.toList();
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value.value;
      final percentage = (value / total * 100);

      return PieChartSectionData(
        value: value,
        color: _getColorForIndex(index),
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
      );
    }).toList();
  }

  List<PieChartSectionData> _getPieSectionsMonth(Map<String, double> caloriesByMonth) {
    final total = caloriesByMonth.values.fold(0.0, (a, b) => a + b);
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey[300],
          title: 'Chưa có dữ liệu',
          radius: 80,
          titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ];
    }

    final entries = caloriesByMonth.entries.toList();
    return entries.asMap().entries.map((entry) {
      final index = entry.key;
      final value = entry.value.value;
      final percentage = (value / total * 100);

      return PieChartSectionData(
        value: value,
        color: _getMonthColor(index),
        radius: 80,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
      );
    }).toList();
  }

  Color _getColorForIndex(int index) {
    const colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.cyan,
      Colors.amber,
    ];
    return colors[index % colors.length];
  }

  Color _getMonthColor(int index) {
    const colors = [
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.cyan,
      Colors.teal,
      Colors.pink,
      Colors.brown,
      Colors.grey,
    ];
    return colors[index % colors.length];
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
