import 'dart:convert';
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
  bool _loading = true;
  List<Map<String, dynamic>> _allMeals = [];
  List<Map<String, dynamic>> _filteredMeals = [];

  String _searchQuery = "";
  DateTime? _filterDate;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchAllMeals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAllMeals() async {
    setState(() {
      _loading = true;
    });

    // Gọi API getMeals không truyền tham số để lấy toàn bộ lịch sử
    final data = await _apiService.getMeals();

    setState(() {
      _allMeals = data;
      _applyFilterAndSearch();
      _loading = false;
    });
  }

  void _applyFilterAndSearch() {
    List<Map<String, dynamic>> temp = List.from(_allMeals);

    // 1. Lọc theo ngày nếu có chọn
    if (_filterDate != null) {
      final dateStr = DateFormat('yyyy-MM-dd').format(_filterDate!);
      temp = temp.where((m) => m['date'] == dateStr).toList();
    }

    // 2. Tìm kiếm theo tên món ăn
    if (_searchQuery.isNotEmpty) {
      temp = temp.where((m) {
        final name = (m['name'] ?? '').toString().toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredMeals = temp;
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

  Future<void> _deleteMeal(String id) async {
    final ok = await _apiService.deleteMeal(id);
    if (ok) {
      setState(() {
        _allMeals.removeWhere((m) => m['_id'] == id || m['id'] == id);
        _applyFilterAndSearch();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa bữa ăn khỏi nhật ký')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa thất bại')),
      );
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '--:--';
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      return DateFormat('HH:mm').format(dt);
    } catch (e) {
      return '--:--';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildMealThumbnail(String? imageUrl) {
    if (imageUrl != null && imageUrl.startsWith('data:')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final bytes = base64Decode(base64String);
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.memory(
            bytes,
            width: 54,
            height: 54,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultThumbnail(),
          ),
        );
      } catch (e) {
        return _buildDefaultThumbnail();
      }
    }
    return _buildDefaultThumbnail();
  }

  Widget _buildDefaultThumbnail() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Center(
        child: Text('🍽️', style: TextStyle(fontSize: 22)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Lịch sử Nhật ký Calo',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                            _applyFilterAndSearch();
                          },
                          decoration: const InputDecoration(
                            hintText: 'Tìm kiếm món ăn...',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                            prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Button phễu lọc theo Ngày
                    IconButton(
                      icon: Icon(
                        Icons.filter_alt_outlined,
                        color: _filterDate != null ? AppTheme.primary : Colors.grey[600],
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

          // Main history list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMeals.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.no_food_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _allMeals.isEmpty 
                                  ? 'Nhật ký của bạn đang trống!' 
                                  : 'Không tìm thấy kết quả phù hợp',
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchAllMeals,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _filteredMeals.length,
                          itemBuilder: (context, index) {
                            final m = _filteredMeals[index];
                            final name = m['name'] ?? 'Bữa ăn';
                            final cal = (m['calories'] as num?)?.toDouble() ?? 0.0;
                            final type = m['mealType'] ?? 'AI Log';
                            final imageUrl = m['imageUrl'];
                            final dateStr = m['date'] ?? '';
                            final id = m['_id'] ?? m['id'] ?? '';
                            final timeStr = _formatTime(m['timestamp']);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Theme(
                                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: _buildMealThumbnail(imageUrl),
                                    title: Text(
                                      name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.purple.withOpacity(0.08),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              type,
                                              style: const TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(Icons.access_time, size: 12, color: Colors.grey[500]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$timeStr - ${_formatDate(dateStr)}',
                                            style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '+${cal.toStringAsFixed(0)} kcal',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                          onPressed: id.isEmpty ? null : () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (c) => AlertDialog(
                                                title: const Text('Xác nhận'),
                                                content: const Text('Bạn có chắc muốn xóa bữa ăn này khỏi nhật ký?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(c, false),
                                                    child: const Text('Hủy'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(c, true),
                                                    child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await _deleteMeal(id);
                                            }
                                          },
                                        ),
                                      ],
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
}
