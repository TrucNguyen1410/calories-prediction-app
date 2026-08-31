import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/app_toast.dart';
import '../widgets/animated_icon_button.dart';

/// Trang Quản trị — chỉ tài khoản role='admin' truy cập (đã chặn ở cả backend).
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _feedback = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _api.getAdminStats(),
      _api.getAdminUsers(),
      _api.getAdminFeedback(),
    ]);
    if (!mounted) return;
    setState(() {
      _stats = (results[0] as Map<String, dynamic>)['data'] ?? {};
      _users = results[1] as List<Map<String, dynamic>>;
      _feedback = results[2] as List<Map<String, dynamic>>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trang quản trị'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          actions: [AnimatedIconButton(icon: Icons.refresh, onPressed: _load)],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Tổng quan'),
              Tab(text: 'Người dùng'),
              Tab(text: 'Phản hồi'),
            ],
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildStatsTab(theme),
                  _buildUsersTab(theme),
                  _buildFeedbackTab(theme),
                ],
              ),
      ),
    );
  }

  int _n(String k) {
    final v = _stats[k];
    return v is num ? v.toInt() : 0;
  }

  Widget _buildStatsTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroHeader(theme),
          const SizedBox(height: 18),
          _buildKpiGrid(theme),
          const SizedBox(height: 18),
          _buildContentChart(theme),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Header hero: tổng người dùng + đăng ký mới
  Widget _buildHeroHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8A2BE2), Color(0xFF4B0082)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF8A2BE2).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng người dùng', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text('${_n('totalUsers')}',
                    style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, height: 1)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text('+${_n('newUsers')} người dùng mới trong 7 ngày',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.groups_rounded, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(ThemeData theme) {
    final tiles = [
      ['Bữa ăn', _n('totalMeals'), Icons.restaurant_rounded, const Color(0xFFF59E0B)],
      ['Buổi tập', _n('totalWorkouts'), Icons.fitness_center_rounded, const Color(0xFF10B981)],
      ['Phiên chat AI', _n('totalSessions'), Icons.chat_bubble_rounded, const Color(0xFF6366F1)],
      ['Phản hồi', _n('totalFeedback'), Icons.feedback_rounded, const Color(0xFF06B6D4)],
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.7,
      children: tiles.map((t) {
        final color = t[3] as Color;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: Icon(t[2] as IconData, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${t[1]}',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: theme.textTheme.bodyLarge?.color)),
                    Text(t[0] as String, style: TextStyle(fontSize: 11, color: theme.hintColor), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // Biểu đồ cột 1 tông màu: khối lượng nội dung trong hệ thống
  Widget _buildContentChart(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final labels = ['Bữa ăn', 'Buổi tập', 'Phiên AI', 'Phản hồi'];
    final values = [_n('totalMeals'), _n('totalWorkouts'), _n('totalSessions'), _n('totalFeedback')];
    final maxV = (values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b)).toDouble();
    final maxY = (maxV < 5 ? 5 : maxV) * 1.25;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Khối lượng dữ liệu trong hệ thống',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: theme.textTheme.bodyLarge?.color)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                gridData: FlGridData(
                  show: true, drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) => FlLine(color: isDark ? const Color(0xFF35373C) : Colors.grey[200]!, strokeWidth: 1, dashArray: [4, 4]),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(labels[i], style: TextStyle(fontSize: 10, color: theme.hintColor, fontWeight: FontWeight.w500)),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(values.length, (i) {
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(
                      toY: values[i].toDouble(),
                      color: AppTheme.primary,
                      width: 26,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ], showingTooltipIndicators: []);
                }),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark ? const Color(0xFF2B2D31) : Colors.black87,
                    getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                      '${labels[group.x]}\n${rod.toY.toInt()}',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(ThemeData theme) {
    if (_users.isEmpty) return Center(child: Text('Chưa có người dùng', style: TextStyle(color: theme.hintColor)));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _users.length,
        itemBuilder: (ctx, i) {
          final u = _users[i];
          final isAdmin = u['role'] == 'admin';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (isAdmin ? Colors.redAccent : AppTheme.primary).withOpacity(0.15),
                child: Icon(isAdmin ? Icons.shield : Icons.person,
                    color: isAdmin ? Colors.redAccent : AppTheme.primary),
              ),
              title: Row(
                children: [
                  Flexible(child: Text(u['name']?.toString() ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  if (isAdmin)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                      child: const Text('ADMIN', style: TextStyle(fontSize: 9, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              subtitle: Text(
                '${u['email'] ?? ''}\n${u['gender'] ?? ''} • ${(u['weight'] ?? 0)}kg • ${(u['height'] ?? 0)}cm',
                style: TextStyle(fontSize: 11, color: theme.hintColor),
              ),
              isThreeLine: true,
              trailing: isAdmin
                  ? null
                  : AnimatedIconButton(
                      icon: Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                      onPressed: () => _confirmDelete(u),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeedbackTab(ThemeData theme) {
    if (_feedback.isEmpty) return Center(child: Text('Chưa có phản hồi', style: TextStyle(color: theme.hintColor)));
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _feedback.length,
        itemBuilder: (ctx, i) {
          final f = _feedback[i];
          final dt = DateTime.tryParse(f['createdAt']?.toString() ?? '');
          final dateStr = dt != null ? DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal()) : '';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_circle, size: 18, color: AppTheme.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text('${f['userName']} (${f['userEmail']})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)),
                    Text(dateStr, style: TextStyle(fontSize: 10, color: theme.hintColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(f['content']?.toString() ?? '', style: const TextStyle(fontSize: 13)),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa người dùng?'),
        content: Text('Xóa "${user['name']}" và toàn bộ dữ liệu của họ? Không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xóa', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true) {
      final success = await _api.deleteUserAdmin(user['_id']?.toString() ?? '');
      if (!mounted) return;
      AppToast.show(
        context,
        message: success ? 'Đã xóa người dùng' : 'Xóa thất bại',
        type: success ? AppToastType.success : AppToastType.error,
      );
      if (success) _load();
    }
  }
}
