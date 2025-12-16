import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme.dart';

class MealHistoryScreen extends StatefulWidget {
  const MealHistoryScreen({Key? key}) : super(key: key);

  @override
  State<MealHistoryScreen> createState() => _MealHistoryScreenState();
}

class _MealHistoryScreenState extends State<MealHistoryScreen> {
  final ApiService _apiService = ApiService();
  DateTime _selected = DateTime.now();
  bool _loading = true;
  List<Map<String, dynamic>> _meals = [];

  @override
  void initState() {
    super.initState();
    _fetchMealsForDate(_selected);
  }

  Future<void> _fetchMealsForDate(DateTime date) async {
    setState(() {
      _loading = true;
      _meals = [];
    });

    final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final data = await _apiService.getMeals(dateStr);

    setState(() {
      _meals = data;
      _loading = false;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selected = picked);
      await _fetchMealsForDate(picked);
    }
  }

  Future<void> _deleteMeal(String id) async {
    final ok = await _apiService.deleteMeal(id);
    if (ok) {
      setState(() => _meals.removeWhere((m) => m['_id'] == id));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa bữa ăn')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xóa thất bại')));
    }
  }

  String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử nạp calo'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(child: Text('Ngày: ${_formatDate(_selected)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                ElevatedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Chọn ngày'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryDark),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _meals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [Icon(Icons.no_food_outlined, size: 56, color: Colors.grey), SizedBox(height: 10), Text('Chưa có bữa ăn cho ngày này', style: TextStyle(color: Colors.grey))],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _fetchMealsForDate(_selected),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _meals.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final m = _meals[index];
                            final name = m['name'] ?? 'Bữa ăn';
                            final cal = (m['calories'] as num?)?.toDouble() ?? 0.0;
                            final type = m['mealType'] ?? '';
                            final id = m['_id'] ?? m['id'] ?? '';

                            return Container(
                              decoration: AppTheme.cardDecoration,
                              child: ListTile(
                                leading: const Icon(Icons.fastfood, color: AppTheme.primary),
                                title: Text('$name (${type.toString()})'),
                                subtitle: Text('${cal.toStringAsFixed(0)} kcal'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: id.isEmpty ? null : () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text('Xác nhận'),
                                        content: const Text('Bạn có chắc muốn xóa bữa ăn này?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Hủy')),
                                          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Xóa')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await _deleteMeal(id);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
