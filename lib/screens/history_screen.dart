import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  List<Workout> _filteredWorkouts = [];
  bool _isLoading = true;

  String _searchQuery = "";
  DateTime? _filterDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWorkouts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchWorkouts() async {
    setState(() {
      _isLoading = true;
    });
    final data = await _apiService.getWorkouts();
    setState(() {
      _workouts = data;
      _applyFilterAndSearch();
      _isLoading = false;
    });
  }

  void _applyFilterAndSearch() {
    List<Workout> temp = List.from(_workouts);

    // 1. Lọc theo ngày
    if (_filterDate != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_filterDate!);
      temp = temp.where((w) {
        try {
          final parsedDate = DateTime.parse(w.date);
          final parsedDateStr = DateFormat('yyyy-MM-dd').format(parsedDate);
          return parsedDateStr == dateStr;
        } catch (_) {
          return w.date.startsWith(dateStr);
        }
      }).toList();
    }

    // 2. Tìm kiếm theo tên bài tập
    if (_searchQuery.isNotEmpty) {
      temp = temp.where((w) {
        final activity = w.activityType.toLowerCase();
        return activity.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredWorkouts = temp;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _filterDate = picked;
      });
      _applyFilterAndSearch();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _filterDate = null;
    });
    _applyFilterAndSearch();
  }

  String _formatDate(String date) {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return date;
    }
  }

  String _formatTime(String date) {
    try {
      final parsed = DateTime.parse(date).toLocal();
      return DateFormat('HH:mm').format(parsed);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1F22) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Lịch sử tập luyện",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFF2F3F5) : Colors.black,
            fontSize: 18,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF2B2D31) : Colors.white,
        centerTitle: true,
        elevation: 0.5,
        iconTheme: IconThemeData(color: isDark ? const Color(0xFFF2F3F5) : Colors.black),
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          Container(
            color: isDark ? const Color(0xFF2B2D31) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1F22) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(color: isDark ? const Color(0xFFF2F3F5) : Colors.black87, fontSize: 14),
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                            _applyFilterAndSearch();
                          },
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm bài tập...',
                            hintStyle: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey, fontSize: 13),
                            prefixIcon: Icon(Icons.search, color: isDark ? const Color(0xFF949BA4) : Colors.grey, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Button phễu lọc theo Ngày
                    IconButton(
                      icon: Icon(
                        Icons.filter_alt_outlined,
                        color: _filterDate != null ? AppTheme.primary : (isDark ? const Color(0xFF949BA4) : Colors.grey[600]),
                      ),
                      onPressed: _pickDate,
                      tooltip: 'Lọc theo ngày',
                    ),
                  ],
                ),
                // Hiển thị trạng thái lọc ngày
                if (_filterDate != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Ngày: ${DateFormat('dd/MM/yyyy').format(_filterDate!)}',
                              style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _clearDateFilter,
                              child: Icon(Icons.close, size: 14, color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Main List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredWorkouts.isEmpty
                    ? _buildEmptyHistory(isDark)
                    : RefreshIndicator(
                        onRefresh: _fetchWorkouts,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredWorkouts.length,
                          itemBuilder: (context, index) {
                            final w = _filteredWorkouts[index];
                            final timeStr = _formatTime(w.date);
                            final dateStr = _formatDate(w.date);
                            final dateTimeDisplay = timeStr.isNotEmpty ? '$timeStr - $dateStr' : dateStr;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF2B2D31) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: isDark ? Border.all(color: const Color(0xFF35373C), width: 1) : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(isDark ? 0.1 : 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.directions_run_rounded, color: Colors.blueAccent),
                                ),
                                title: Text(
                                  w.activityType,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isDark ? const Color(0xFFF2F3F5) : Colors.black87,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.access_time, size: 12, color: isDark ? const Color(0xFF949BA4) : Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${w.duration} phút • $dateTimeDisplay',
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF949BA4) : Colors.grey[600],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "-${w.calories.toStringAsFixed(0)} kcal",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
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

  Widget _buildEmptyHistory(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off,
              size: 60,
              color: isDark ? const Color(0xFF949BA4) : Colors.grey,
            ),
            const SizedBox(height: 10),
            Text(
              _workouts.isEmpty ? "Chưa có dữ liệu tập luyện" : "Không tìm thấy kết quả phù hợp",
              style: TextStyle(
                color: isDark ? const Color(0xFF949BA4) : Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
