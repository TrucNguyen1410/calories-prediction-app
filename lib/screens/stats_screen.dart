import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme.dart';
import '../providers/health_provider.dart';
import 'meal_history_screen.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends ConsumerState<StatsScreen> {
  bool _showWeightTrend = true; // true = Cân nặng, false = BMI

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
                        IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.primary),
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
                      value: healthState.maxBurnedDayName.split(' ')[0],
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
