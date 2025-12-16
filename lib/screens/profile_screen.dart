import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String name;
  final String email;

  const ProfileScreen({Key? key, required this.name, required this.email})
      : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadLocalUser();
  }

  Future<void> _loadLocalUser() async {
    final data = await _apiService.getUserData();
    setState(() {
      _userData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Cá nhân"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Gradient header similar to predict screen
            GestureDetector(
              onTap: _showEditProfileDialog,
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.cardDecoration.copyWith(
                  // overlay a subtle gradient at top
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primary,
                      child: const Icon(Icons.person, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_userData?['name'] ?? widget.name,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_userData?['email'] ?? widget.email,
                              style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),

            // --- Danh mục chính ---
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSectionTitle("Tài khoản"),
                    _buildListTile(
                      icon: Icons.lock_outline,
                      title: "Đổi mật khẩu",
                      onTap: () => _showChangePasswordDialog(),
                    ),
                    const SizedBox(height: 10),
                    _buildSectionTitle("Ứng dụng"),
                    _buildListTile(
                      icon: Icons.info_outline,
                      title: "Phiên bản",
                      trailing: const Text(
                        "1.0.0",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    _buildListTile(
                      icon: Icons.settings_outlined,
                      title: "Cài đặt khác",
                      trailing: const Text(
                        "Sắp ra mắt...",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // --- Nút đăng xuất cố định ---
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Text(
                    "Đăng xuất",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====== WIDGET PHỤ ======
  Widget _buildSectionTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title),
        trailing: trailing ??
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _userData?['name'] ?? widget.name);
    final emailController = TextEditingController(text: _userData?['email'] ?? widget.email);
    final phoneController = TextEditingController(text: _userData?['phone']?.toString() ?? '');
    final ageController = TextEditingController(text: _userData?['age']?.toString() ?? '');
    String gender = _userData?['gender'] ?? 'Nam';
    final weightController = TextEditingController(text: _userData?['weight']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(Icons.person, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Thông tin người dùng', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: InputDecoration(labelText: 'Tên')),
                const SizedBox(height: 8),
                TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
                const SizedBox(height: 8),
                TextField(controller: phoneController, decoration: InputDecoration(labelText: 'Số điện thoại'), keyboardType: TextInputType.phone),
                const SizedBox(height: 8),
                TextField(controller: ageController, decoration: InputDecoration(labelText: 'Tuổi'), keyboardType: TextInputType.number),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: gender,
                  items: ['Nam', 'Nữ', 'Khác'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                  onChanged: (v) { if (v != null) gender = v; },
                  decoration: InputDecoration(labelText: 'Giới tính'),
                ),
                const SizedBox(height: 8),
                TextField(controller: weightController, decoration: InputDecoration(labelText: 'Cân nặng (kg)'), keyboardType: TextInputType.number),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                // collect values
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final phone = phoneController.text.trim();
                final age = int.tryParse(ageController.text.trim());
                final weight = double.tryParse(weightController.text.trim());

                // Update backend for fields supported (height/weight/gender)
                try {
                  final userId = _userData?['id'] ?? _userData?['_id'] ?? null;
                  if (userId != null) {
                    await _apiService.updateUserProfile(userId: userId.toString(), height: null, weight: weight, gender: gender);
                  }

                  // Update local stored userData
                  final prefs = await SharedPreferences.getInstance();
                  final raw = prefs.getString('userData');
                  Map<String, dynamic> local = {};
                  if (raw != null) {
                    try { local = json.decode(raw); } catch (_) { local = {}; }
                  }
                  local['name'] = name;
                  local['email'] = email;
                  if (phone.isNotEmpty) local['phone'] = phone;
                  if (age != null) local['age'] = age;
                  if (weight != null) local['weight'] = weight;
                  local['gender'] = gender;
                  await prefs.setString('userData', json.encode(local));

                  setState(() { _userData = local; });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cập nhật thông tin thành công'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  // Hiển thị dialog đổi mật khẩu
  void _showChangePasswordDialog() {
    final oldController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(Icons.lock, color: Colors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldController,
                  decoration: InputDecoration(labelText: 'Mật khẩu hiện tại'),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: newController,
                  decoration: InputDecoration(labelText: 'Mật khẩu mới'),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmController,
                  decoration: InputDecoration(labelText: 'Xác nhận mật khẩu mới'),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () async {
                final oldP = oldController.text.trim();
                final newP = newController.text.trim();
                final conf = confirmController.text.trim();

                if (oldP.isEmpty || newP.isEmpty || conf.isEmpty) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')));
                  return;
                }
                if (newP.length < 6) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu mới cần ít nhất 6 ký tự')));
                  return;
                }
                if (newP != conf) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mật khẩu mới và xác nhận không khớp')));
                  return;
                }

                try {
                  final userId = _userData?['id'] ?? _userData?['_id'] ?? null;
                  if (userId == null) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Không tìm thấy thông tin người dùng')));
                    return;
                  }

                  final res = await _apiService.changePassword(userId: userId.toString(), oldPassword: oldP, newPassword: newP);
                  if (res['success'] == true) {
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Đổi mật khẩu thành công'), backgroundColor: Colors.green));
                    }
                  } else {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Đổi mật khẩu thất bại'), backgroundColor: Colors.red));
                  }
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
}
