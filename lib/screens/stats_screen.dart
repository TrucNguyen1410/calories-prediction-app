import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../providers/health_provider.dart';
import '../services/api_service.dart';
import 'meal_history_screen.dart';
import '../widgets/app_toast.dart';
import '../widgets/animated_icon_button.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  bool _showWeightTrend = true; // true = Cân nặng, false = BMI
  bool _loadingInsight = false;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(healthProvider.notifier).refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(healthProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (healthState.isLoading && healthState.userData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: () => ref.read(healthProvider.notifier).refreshAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 0. Nút Phân tích tuần bằng AI
              _buildWeeklyInsightButton(isDark),
              const SizedBox(height: 20),

              // 1. Apple Health Bento-style Card cho Calo 7 ngày
              _buildSectionTitle('Dinh dưỡng tuần này'),
              const SizedBox(height: 10),
              Container(
                decoration: _buildCardDecoration(theme),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calo nạp vào hàng ngày',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF949BA4) : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${healthState.averageIntake.toStringAsFixed(0)} kcal/ngày (TB)',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFFF2F3F5) : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        AnimatedIconButton(
                          icon: Icons.arrow_forward_ios,
                          size: 16,
                          color: AppTheme.primary,
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MealHistoryScreen()),
                            );
                            ref.read(healthProvider.notifier).refreshAll();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: _buildBarChart(healthState, isDark),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 28),

              // 2. Line Chart cho Cân nặng / BMI xu hướng
              _buildSectionTitle('Chỉ số cơ thể'),
              const SizedBox(height: 10),
              Container(
                decoration: _buildCardDecoration(theme),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _showWeightTrend ? 'Xu hướng Cân nặng' : 'Xu hướng chỉ số BMI',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF949BA4) : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Nút chuyển chế độ
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _showWeightTrend = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _showWeightTrend 
                                      ? AppTheme.primary.withOpacity(0.15) 
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Cân nặng',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _showWeightTrend ? AppTheme.primary : (isDark ? const Color(0xFFB5BAC1) : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => setState(() => _showWeightTrend = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: !_showWeightTrend 
                                      ? AppTheme.primary.withOpacity(0.15) 
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'BMI',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: !_showWeightTrend ? AppTheme.primary : (isDark ? const Color(0xFFB5BAC1) : Colors.black54),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: _buildLineChart(healthState, isDark),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 3. Apple Health Highlights (Thông số text)
              _buildSectionTitle('Điểm nổi bật'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildHighlightCard(
                      title: 'TB Nạp Tuần Này',
                      value: '${healthState.averageIntake.toStringAsFixed(0)} kcal',
                      subtitle: 'Trung bình hàng ngày',
                      icon: Icons.restaurant,
                      iconColor: Colors.orangeAccent,
                      isDark: isDark,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildHighlightCard(
                      title: 'Đốt Nhiều Nhất',
                      value: healthState.maxBurnedDayName.contains('(')
                          ? healthState.maxBurnedDayName.split(' (')[0]
                          : healthState.maxBurnedDayName,
                      subtitle: healthState.maxBurnedDayName.contains('(')
                          ? healthState.maxBurnedDayName.substring(healthState.maxBurnedDayName.indexOf('(') + 1, healthState.maxBurnedDayName.indexOf(')'))
                          : 'Chưa có',
                      icon: Icons.local_fire_department,
                      iconColor: Colors.redAccent,
                      isDark: isDark,
                      theme: theme,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? const Color(0xFFF2F3F5) : Colors.black87,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildWeeklyInsightButton(bool isDark) {
    return InkWell(
      onTap: _loadingInsight ? null : _showWeeklyInsight,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8A2BE2), Color(0xFF4B0082)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF8A2BE2).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phân tích tuần bằng AI',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  SizedBox(height: 2),
                  Text('Nhận xét & lời khuyên cá nhân từ dữ liệu 7 ngày',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            _loadingInsight
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showWeeklyInsight() async {
    setState(() => _loadingInsight = true);
    final result = await _apiService.getWeeklyInsight();
    if (!mounted) return;
    setState(() => _loadingInsight = false);

    if (result['success'] != true) {
      AppToast.show(
        context,
        message: result['message'] ?? 'Không thể phân tích',
        type: AppToastType.error,
      );
      return;
    }

    final data = result['data'] as Map<String, dynamic>;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final score = (data['score'] ?? 0) is num ? (data['score'] as num).toInt() : 0;
    final highlights = List<String>.from((data['highlights'] ?? []).map((e) => e.toString()));
    final advice = List<String>.from((data['advice'] ?? []).map((e) => e.toString()));
    final scoreColor = score >= 75 ? Colors.green : (score >= 50 ? Colors.orangeAccent : Colors.redAccent);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                width: 40, height: 5,
                decoration: BoxDecoration(color: isDark ? Colors.grey[800] : Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(data['title']?.toString() ?? 'Phân tích tuần',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Điểm sức khỏe tuần
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: scoreColor.withOpacity(0.12), shape: BoxShape.circle),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$score', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: scoreColor)),
                    Text('điểm', style: TextStyle(fontSize: 12, color: scoreColor)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(data['summary']?.toString() ?? '',
                style: TextStyle(fontSize: 14, height: 1.5, color: isDark ? const Color(0xFFDBDEE1) : Colors.black87)),
            if (highlights.isNotEmpty) ...[
              const SizedBox(height: 20),
              _insightSection('📊 Điểm nổi bật', highlights, Colors.blueAccent, isDark),
            ],
            if (advice.isNotEmpty) ...[
              const SizedBox(height: 16),
              _insightSection('💡 Lời khuyên tuần tới', advice, Colors.green, isDark),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _insightSection(String title, List<String> items, Color color, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        ...items.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(margin: const EdgeInsets.only(top: 6), width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t, style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? const Color(0xFFDBDEE1) : Colors.black87))),
                ],
              ),
            )),
      ],
    );
  }

  BoxDecoration _buildCardDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: theme.dividerColor),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildHighlightCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Container(
      decoration: _buildCardDecoration(theme),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF949BA4) : Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF2F3F5) : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF949BA4) : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(HealthState state, bool isDark) {
    final textColor = isDark ? const Color(0xFF949BA4) : Colors.grey[600]!;
    final gridColor = isDark ? const Color(0xFF35373C) : Colors.grey[200]!;
    
    final maxY = state.weeklyIntake.isEmpty
        ? 2000.0
        : state.weeklyIntake.reduce((a, b) => a > b ? a : b);
    final adjustedMaxY = (maxY < 1000 ? 1000.0 : maxY) * 1.15;

    final today = DateTime.now();
    final List<String> days = [];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      days.add(weekdays[date.weekday - 1]);
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: adjustedMaxY,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => isDark ? const Color(0xFF2B2D31) : Colors.black87,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toStringAsFixed(0)} kcal',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == 0 || value % 500 != 0) return const SizedBox();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    '${(value / 1000).toStringAsFixed(1)}k',
                    style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0) return const SizedBox();
                final index = value.toInt();
                if (index < 0 || index >= days.length) return const SizedBox();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    days[index],
                    style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: gridColor, strokeWidth: 1, dashArray: [4, 4]),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(state.weeklyIntake.length, (index) {
          final val = state.weeklyIntake[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                color: Colors.orangeAccent,
                width: 14,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildLineChart(HealthState state, bool isDark) {
    final textColor = isDark ? const Color(0xFF949BA4) : Colors.grey[600]!;
    final gridColor = isDark ? const Color(0xFF35373C) : Colors.grey[200]!;
    
    final dataList = _showWeightTrend ? state.weeklyWeight : state.weeklyBMI;
    
    final double minY = dataList.isEmpty
        ? 0.0
        : dataList.reduce((a, b) => a < b ? a : b);
    final double maxY = dataList.isEmpty
        ? 100.0
        : dataList.reduce((a, b) => a > b ? a : b);

    final range = maxY - minY;
    final double adjustedMinY = (minY - (range > 0 ? range * 0.15 : 5.0)).clamp(0.0, double.infinity);
    final double adjustedMaxY = maxY + (range > 0 ? range * 0.15 : 5.0);

    final today = DateTime.now();
    final List<String> days = [];
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
      days.add(weekdays[date.weekday - 1]);
    }

    return LineChart(
      LineChartData(
        minY: adjustedMinY,
        maxY: adjustedMaxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => isDark ? const Color(0xFF2B2D31) : Colors.black87,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((touchedSpot) {
                return LineTooltipItem(
                  '${touchedSpot.y.toStringAsFixed(1)} ${_showWeightTrend ? "kg" : "BMI"}',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(color: gridColor, strokeWidth: 1, dashArray: [4, 4]),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) return const SizedBox();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toStringAsFixed(1),
                    style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0) return const SizedBox();
                final index = value.toInt();
                if (index < 0 || index >= days.length) return const SizedBox();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    days[index],
                    style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(dataList.length, (index) {
              return FlSpot(index.toDouble(), dataList[index]);
            }),
            isCurved: true,
            color: _showWeightTrend ? Colors.blueAccent : Colors.teal,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: (_showWeightTrend ? Colors.blueAccent : Colors.teal).withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }
}
