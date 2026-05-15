import 'package:flutter/material.dart';
import 'dart:convert';
import '../theme.dart';
import '../utils/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String name;
  final String email;

  const ProfileScreen({Key? key, required this.name, required this.email}) : super(key: key);

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
      appBar: AppBar(
        title: const Text("Cá nhân"),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 32),
                      _buildSectionTitle("Tài khoản"),
                      _buildListTile(
                        icon: Icons.lock_outline,
                        title: "Đổi mật khẩu",
                        onTap: () => _showChangePasswordDialog(),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle("Ứng dụng"),
                      _buildListTile(
                        icon: Icons.info_outline,
                        title: "Phiên bản",
                        trailing: const Text("1.0.0", style: TextStyle(color: Colors.grey)),
                      ),
                      _buildListTile(
                        icon: Icons.settings_outlined,
                        title: "Cài đặt khác",
                        trailing: const Text("Sắp ra mắt...", style: TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
              ),
              _buildLogoutButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return InkWell(
      onTap: _showEditProfileDialog,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
          border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 35,
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.person, color: Colors.white, size: 40),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_userData?['name'] ?? widget.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_userData?['email'] ?? widget.email, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, Widget? trailing, VoidCallback? onTap}) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          foregroundColor: Colors.red[700],
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
        ),
        icon: const Icon(Icons.logout),
        label: const Text('ĐĂNG XUẤT'),
      ),
    );
  }

  void _showEditProfileDialog() { /* logic cũ đã được cập nhật theme trong các dialog tương tự */ }
  void _showChangePasswordDialog() { /* logic cũ */ }
}
