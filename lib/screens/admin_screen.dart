import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme.dart';

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
          actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
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

  Widget _buildStatsTab(ThemeData theme) {
    final cards = [
      ['Người dùng', _stats['totalUsers'], Icons.people, Colors.blueAccent],
      ['Bữa ăn', _stats['totalMeals'], Icons.restaurant, Colors.orangeAccent],
      ['Buổi tập', _stats['totalWorkouts'], Icons.fitness_center, Colors.green],
      ['Phiên chat AI', _stats['totalSessions'], Icons.chat_bubble, Colors.purpleAccent],
      ['Phản hồi', _stats['totalFeedback'], Icons.feedback, Colors.teal],
      ['User mới (7 ngày)', _stats['newUsers'], Icons.person_add, Colors.pinkAccent],
    ];
    return RefreshIndicator(
      onRefresh: _load,
      child: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: cards.map((c) {
          final color = c[3] as Color;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(c[2] as IconData, color: color, size: 26),
                Text('${c[1] ?? 0}',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
                Text(c[0] as String, style: TextStyle(fontSize: 12, color: theme.hintColor)),
              ],
            ),
          );
        }).toList(),
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
                  : IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Đã xóa người dùng' : 'Xóa thất bại'), backgroundColor: success ? Colors.green : Colors.red),
      );
      if (success) _load();
    }
  }
}
