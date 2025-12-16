import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/api_service.dart';
import '../theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  List<Workout> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWorkouts();
  }

  Future<void> _fetchWorkouts() async {
    final data = await _apiService.getWorkouts();
    setState(() {
      _workouts = data;
      _isLoading = false;
    });
  }

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return "${parsed.day}/${parsed.month}/${parsed.year}";
    } catch (_) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử tập luyện"),
        centerTitle: true,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWorkouts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _workouts.isEmpty
                ? _buildEmptyHistory()
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _workouts.length,
                    itemBuilder: (context, index) {
                      final w = _workouts[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: AppTheme.cardDecoration,
                        child: ListTile(
                          leading: const Icon(Icons.fitness_center, color: AppTheme.primary),
                          title: Text("${w.activityType} - ${w.duration} phút"),
                          subtitle: Text(
                            "Ngày: ${_formatDate(w.date)}\nCalo tiêu hao: ${w.calories.toStringAsFixed(1)} kcal",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 60, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              "Chưa có dữ liệu tập luyện",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
