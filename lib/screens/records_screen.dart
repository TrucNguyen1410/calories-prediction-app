import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../providers/health_provider.dart';
import '../utils/health_calc.dart';
import '../theme.dart';

/// Màn hình "Hồ sơ Sức khỏe": theo dõi xu hướng cân nặng & BMI THẬT theo thời gian,
/// cho phép người dùng ghi nhận số đo mới và xem lịch sử.
class RecordsScreen extends ConsumerStatefulWidget {
  final String title;

  const RecordsScreen({Key? key, this.title = "Hồ sơ Sức khỏe"}) : super(key: key);

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await _apiService.getWeightRecords();
    if (mounted) {
      setState(() {
        _records = records;
        _isLoading = false;
      });
    }
  }

  String _classifyBMI(double bmi) {
    if (bmi <= 0) return "Không xác định";
    if (bmi < 18.5) return "Thiếu cân";
    if (bmi < 23) return "Bình thường";
    if (bmi < 25) return "Thừa cân";
    if (bmi < 30) return "Béo phì độ I";
    return "Béo phì độ II";
  }

  Color _bmiColor(double bmi) {
    if (bmi <= 0) return Colors.grey;
    if (bmi < 18.5) return Colors.orangeAccent;
    if (bmi < 23) return Colors.green;
    if (bmi < 25) return Colors.amber;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final healthState = ref.watch(healthProvider);

    final userData = healthState.userData;
    final currentWeight = (userData?['weight'] ?? 0).toDouble();
    final currentHeight = (userData?['height'] ?? 0).toDouble();
    final hMeters = currentHeight > 0 ? currentHeight / 100.0 : 0.0;
    final currentBMI = (hMeters > 0 && currentWeight > 0)
        ? double.parse((currentWeight / (hMeters * hMeters)).toStringAsFixed(1))
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWeightDialog(currentHeight),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Cập nhật cân nặng", style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecords,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(currentWeight, currentBMI, isDark, theme),
                  const SizedBox(height: 12),
                  _buildTargetCard(healthState, isDark, theme),
                  const SizedBox(height: 20),
                  _buildChartCard(isDark, theme),
                  const SizedBox(height: 20),
                  _buildHistoryHeader(theme),
                  const SizedBox(height: 8),
                  if (_records.isEmpty)
                    _buildEmptyState(theme)
                  else
                    ..._records.map((r) => _buildRecordTile(r, isDark, theme)),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(double weight, double bmi, bool isDark, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Cân nặng hiện tại", style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  weight > 0 ? "${weight.toStringAsFixed(1)} kg" : "Chưa có",
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 50, color: Colors.white24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("Chỉ số BMI", style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  bmi > 0 ? bmi.toStringAsFixed(1) : "--",
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Text(
                  _classifyBMI(bmi),
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetCard(HealthState state, bool isDark, ThemeData theme) {
    final target = state.dailyCalorieTarget;
    final goal = state.userData?['goal']?.toString() ?? 'maintain';
    final activity = state.userData?['activityLevel']?.toString() ?? 'light';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_fire_department, color: Colors.orangeAccent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Mục tiêu calo nạp / ngày",
                    style: TextStyle(fontSize: 12, color: theme.hintColor)),
                const SizedBox(height: 2),
                Text("${target.toStringAsFixed(0)} kcal",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                const SizedBox(height: 2),
                Text(
                  "${HealthCalc.goalLabels[goal] ?? goal} • ${HealthCalc.activityLabels[activity] ?? activity}",
                  style: TextStyle(fontSize: 11, color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(bool isDark, ThemeData theme) {
    // Sắp xếp theo thời gian tăng dần để vẽ biểu đồ, lấy tối đa 12 mốc gần nhất
    final chrono = List<Map<String, dynamic>>.from(_records.reversed);
    final display = chrono.length > 12 ? chrono.sublist(chrono.length - 12) : chrono;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text("Xu hướng cân nặng (kg)",
                  style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: display.length < 2
                ? Center(
                    child: Text(
                      "Cần ít nhất 2 lần đo để hiển thị biểu đồ.",
                      style: TextStyle(color: theme.hintColor, fontSize: 13),
                    ),
                  )
                : _buildLineChart(display, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data, bool isDark) {
    final textColor = isDark ? const Color(0xFF949BA4) : Colors.grey[600]!;
    final gridColor = isDark ? const Color(0xFF35373C) : Colors.grey[200]!;

    final weights = data.map((r) => (r['weight'] ?? 0).toDouble()).toList().cast<double>();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final range = maxW - minW;
    final adjMinY = (minW - (range > 0 ? range * 0.2 : 2.0)).clamp(0.0, double.infinity);
    final adjMaxY = maxW + (range > 0 ? range * 0.2 : 2.0);

    return LineChart(
      LineChartData(
        minY: adjMinY,
        maxY: adjMaxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => isDark ? const Color(0xFF2B2D31) : Colors.black87,
            getTooltipItems: (spots) => spots
                .map((s) => LineTooltipItem(
                      '${s.y.toStringAsFixed(1)} kg',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ))
                .toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(color: gridColor, strokeWidth: 1, dashArray: [4, 4]),
        ),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) return const SizedBox();
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(value.toStringAsFixed(0),
                      style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold)),
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
                if (index < 0 || index >= data.length) return const SizedBox();
                final dt = DateTime.tryParse(data[index]['date']?.toString() ?? '');
                final label = dt != null ? DateFormat('dd/MM').format(dt) : '';
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(label, style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold)),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(weights.length, (i) => FlSpot(i.toDouble(), weights[i])),
            isCurved: true,
            color: AppTheme.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: AppTheme.primary.withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryHeader(ThemeData theme) {
    return Row(
      children: [
        const Icon(Icons.history, color: AppTheme.primary, size: 20),
        const SizedBox(width: 8),
        Text("Lịch sử đo (${_records.length})",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: theme.textTheme.bodyLarge?.color)),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.monitor_weight_outlined, size: 48, color: theme.hintColor),
          const SizedBox(height: 12),
          Text("Chưa có dữ liệu đo.\nNhấn \"Cập nhật cân nặng\" để bắt đầu theo dõi.",
              textAlign: TextAlign.center, style: TextStyle(color: theme.hintColor)),
        ],
      ),
    );
  }

  Widget _buildRecordTile(Map<String, dynamic> r, bool isDark, ThemeData theme) {
    final weight = (r['weight'] ?? 0).toDouble();
    final bmi = (r['bmi'] ?? 0).toDouble();
    final dt = DateTime.tryParse(r['date']?.toString() ?? '');
    final dateStr = dt != null ? DateFormat('dd/MM/yyyy • HH:mm').format(dt.toLocal()) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _bmiColor(bmi).withOpacity(0.15),
          child: Icon(Icons.monitor_weight, color: _bmiColor(bmi)),
        ),
        title: Text("${weight.toStringAsFixed(1)} kg",
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          "$dateStr${bmi > 0 ? "  •  BMI ${bmi.toStringAsFixed(1)} (${_classifyBMI(bmi)})" : ""}",
          style: TextStyle(fontSize: 12, color: theme.hintColor),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          onPressed: () => _confirmDelete(r['_id']?.toString()),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String? id) async {
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa bản ghi?"),
        content: const Text("Bạn có chắc muốn xóa mốc đo này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok == true) {
      final success = await _apiService.deleteWeightRecord(id);
      if (success) {
        await _loadRecords();
        await ref.read(healthProvider.notifier).refreshAll();
      }
    }
  }

  Future<void> _showAddWeightDialog(double currentHeight) async {
    final weightController = TextEditingController();
    final heightController =
        TextEditingController(text: currentHeight > 0 ? currentHeight.toStringAsFixed(0) : '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Cập nhật cân nặng"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "Cân nặng (kg)", prefixIcon: Icon(Icons.scale)),
                  validator: (v) {
                    final d = double.tryParse(v ?? '');
                    if (d == null) return "Nhập số hợp lệ";
                    if (d < 20 || d > 400) return "Từ 20 đến 400 kg";
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: heightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: "Chiều cao (cm)", prefixIcon: Icon(Icons.height)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return null; // không bắt buộc
                    final d = double.tryParse(v);
                    if (d == null || d < 50 || d > 260) return "Từ 50 đến 260 cm";
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      final result = await _apiService.addWeightRecord(
                        weight: double.parse(weightController.text),
                        height: heightController.text.isNotEmpty
                            ? double.tryParse(heightController.text)
                            : null,
                      );
                      if (!mounted) return;
                      Navigator.pop(ctx);
                      if (result['success'] == true) {
                        await _loadRecords();
                        await ref.read(healthProvider.notifier).refreshAll();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("✅ Đã lưu cân nặng!"), backgroundColor: Colors.green),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['message'] ?? "Lỗi"), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Lưu"),
            ),
          ],
        ),
      ),
    );
  }
}
