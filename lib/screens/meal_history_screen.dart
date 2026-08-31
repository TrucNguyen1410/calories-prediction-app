import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/animated_icon_button.dart';

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
      AppToast.show(context, message: 'Đã xóa bữa ăn khỏi nhật ký', type: AppToastType.success);
    } else {
      AppToast.show(context, message: 'Xóa thất bại', type: AppToastType.error);
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

  // Health Score hôm nay: tính từ Chất xơ / Đường / Natri các bữa ăn đã ghi hôm
  // nay, theo ngưỡng khuyến nghị của WHO (đường) và FDA (natri, chất xơ).
  Widget _buildHealthScoreCard(bool isDark) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayMeals = _allMeals.where((m) => m['date'] == todayStr).toList();
    final hasData = todayMeals.isNotEmpty;

    double totalFiber = 0, totalSugar = 0, totalSodium = 0, totalCarbs = 0;
    for (final m in todayMeals) {
      totalFiber += (m['fiber'] ?? 0).toDouble();
      totalSugar += (m['sugar'] ?? 0).toDouble();
      totalSodium += (m['sodium'] ?? 0).toDouble();
      totalCarbs += (m['carbs'] ?? 0).toDouble();
    }
    final netCarbs = (totalCarbs - totalFiber).clamp(0, double.infinity);

    final fiberOk = totalFiber >= 25;
    final sugarOk = totalSugar <= 50;
    final sodiumOk = totalSodium <= 2300;

    double score = 10.0;
    if (!fiberOk) score -= ((25 - totalFiber) / 10).clamp(0, 2);
    if (!sugarOk) score -= ((totalSugar - 50) / 20).clamp(0, 3);
    if (!sodiumOk) score -= ((totalSodium - 2300) / 700).clamp(0, 3);
    score = score.clamp(0, 10).toDouble();

    String status;
    Color statusColor;
    if (!hasData) {
      status = 'Chưa có dữ liệu hôm nay';
      statusColor = Colors.grey;
    } else if (score >= 8) {
      status = 'Tuyệt vời';
      statusColor = Colors.green;
    } else if (score >= 6) {
      status = 'Tốt';
      statusColor = Colors.green;
    } else if (score >= 4) {
      status = 'Khá';
      statusColor = Colors.orange;
    } else {
      status = 'Cần cải thiện';
      statusColor = Colors.redAccent;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2B2D31) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.055),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Health Score hôm nay',
                        style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF949BA4) : Colors.grey[600], fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(status, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87)),
                  ],
                ),
              ),
              CircularPercentIndicator(
                radius: 32,
                lineWidth: 7,
                percent: hasData ? (score / 10).clamp(0.0, 1.0).toDouble() : 0.0,
                circularStrokeCap: CircularStrokeCap.round,
                backgroundColor: isDark ? const Color(0xFF35373C) : Colors.grey[200]!,
                progressColor: statusColor,
                center: Text(
                  hasData ? '${score.toStringAsFixed(0)}/10' : '--/10',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildNutrientScoreRow(LucideIcons.wheat, 'Chất xơ', '${totalFiber.toStringAsFixed(0)}g', fiberOk, isDark),
          _buildNutrientScoreRow(LucideIcons.circleDot, 'Net Carbs', '${netCarbs.toStringAsFixed(0)}g', true, isDark),
          _buildNutrientScoreRow(LucideIcons.candy, 'Đường', '${totalSugar.toStringAsFixed(0)}g', sugarOk, isDark),
          _buildNutrientScoreRow(LucideIcons.droplet, 'Natri', '${totalSodium.toStringAsFixed(0)}mg', sodiumOk, isDark),
        ],
      ),
    );
  }

  Widget _buildNutrientScoreRow(IconData icon, String label, String value, bool isGood, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? const Color(0xFF949BA4) : Colors.grey[600]),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFFB5BAC1) : Colors.black54, fontWeight: FontWeight.w500)),
          ),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87)),
          const SizedBox(width: 8),
          Container(width: 8, height: 8, decoration: BoxDecoration(color: isGood ? Colors.green : Colors.redAccent, shape: BoxShape.circle)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E1F22) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Lịch sử Nhật ký Calo',
          style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF2F3F5) : Colors.black, fontSize: 18),
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
                            hintText: 'Tìm kiếm món ăn...',
                            hintStyle: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey, fontSize: 13),
                            prefixIcon: Icon(LucideIcons.search, color: isDark ? const Color(0xFF949BA4) : Colors.grey, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Button phễu lọc theo Ngày
                    AnimatedIconButton(
                      icon: LucideIcons.filter,
                      color: _filterDate != null ? AppTheme.primary : (isDark ? const Color(0xFF949BA4) : Colors.grey[600]),
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
                            Icon(LucideIcons.calendar, size: 12, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Ngày: ${DateFormat('dd/MM/yyyy').format(_filterDate!)}',
                              style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: _clearDateFilter,
                              child: Icon(LucideIcons.x, size: 14, color: AppTheme.primary),
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
          _buildHealthScoreCard(isDark),
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
                            Icon(LucideIcons.utensilsCrossed, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _allMeals.isEmpty 
                                  ? 'Nhật ký của bạn đang trống!' 
                                  : 'Không tìm thấy kết quả phù hợp',
                              style: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey[600], fontSize: 14),
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Theme(
                                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: _buildMealThumbnail(imageUrl),
                                    title: Text(
                                      name,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        crossAxisAlignment: WrapCrossAlignment.center,
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
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(LucideIcons.clock, size: 12, color: isDark ? const Color(0xFF949BA4) : Colors.grey[500]),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$timeStr - ${_formatDate(dateStr)}',
                                                style: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey[600], fontSize: 11),
                                              ),
                                            ],
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
                                        Container(
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E1F22) : Colors.transparent,
                                            shape: BoxShape.circle,
                                            boxShadow: isDark
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFFBB86FC).withOpacity(0.4),
                                                      blurRadius: 10,
                                                      spreadRadius: 1,
                                                    )
                                                  ]
                                                : null,
                                          ),
                                          child: AnimatedIconButton(
                                            icon: LucideIcons.trash2,
                                            color: isDark ? const Color(0xFFBB86FC) : Colors.redAccent,
                                            size: 20,
                                            onPressed: id.isEmpty ? null : () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (c) => AlertDialog(
                                                  backgroundColor: isDark ? const Color(0xFF1E1F22) : Colors.white,
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
