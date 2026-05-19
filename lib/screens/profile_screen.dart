import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String name;
  final String email;

  const ProfileScreen({Key? key, required this.name, required this.email}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final userData = authState.userData;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Hồ sơ Cá nhân"),
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
                      _buildProfileHeader(userData),
                      const SizedBox(height: 32),
                      _buildSectionTitle("Thông số sinh thể (BMI)"),
                      _buildBiometricDetailsCard(userData),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Tài khoản & Bảo mật"),
                      _buildListTile(
                        icon: Icons.lock_outline,
                        title: "Đổi mật khẩu",
                        onTap: () => _showChangePasswordDialog(),
                      ),
                      const SizedBox(height: 16),
                      _buildSectionTitle("Ứng dụng"),
                      _buildListTile(
                        icon: Icons.sync_lock,
                        title: "Bảo mật & Đồng bộ Google Fit",
                        trailing: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🔒 Hệ thống tự động đồng bộ hóa Google Fit an toàn.'),
                              backgroundColor: Colors.blueAccent,
                            ),
                          );
                        },
                      ),
                      _buildListTile(
                        icon: Icons.info_outline,
                        title: "Phiên bản ứng dụng",
                        trailing: const Text("1.2.0-Alpha", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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

  Widget _buildProfileHeader(Map<String, dynamic>? userData) {
    final displayName = userData?['name'] ?? widget.name;
    final displayEmail = userData?['email'] ?? widget.email;

    return InkWell(
      onTap: () => _showEditProfileDialog(userData),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.person_outline, color: Colors.white, size: 36),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(displayName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(displayEmail, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBiometricDetailsCard(Map<String, dynamic>? userData) {
    final height = userData?['height'] ?? 0;
    final weight = userData?['weight'] ?? 0;
    final gender = userData?['gender'] ?? 'Chưa xác định';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _buildBiometricRow(Icons.height, "Chiều cao", height > 0 ? "$height cm" : "-- cm"),
          const Divider(height: 24),
          _buildBiometricRow(Icons.scale_outlined, "Cân nặng", weight > 0 ? "$weight kg" : "-- kg"),
          const Divider(height: 24),
          _buildBiometricRow(Icons.wc_outlined, "Giới tính", gender == 'male' ? 'Nam' : (gender == 'female' ? 'Nữ' : gender)),
        ],
      ),
    );
  }

  Widget _buildBiometricRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black54)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 15)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, Widget? trailing, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ElevatedButton.icon(
        onPressed: () async {
          await ref.read(authProvider.notifier).logout();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[50],
          foregroundColor: Colors.red[700],
          minimumSize: const Size(double.infinity, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        icon: const Icon(Icons.logout),
        label: const Text('ĐĂNG XUẤT TÀI KHOẢN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.8)),
      ),
    );
  }

  void _showEditProfileDialog(Map<String, dynamic>? userData) {
    final weightController = TextEditingController(text: (userData?['weight'] ?? '').toString());
    final heightController = TextEditingController(text: (userData?['height'] ?? '').toString());
    String selectedGender = userData?['gender'] ?? 'male';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Cập nhật chỉ số sinh thể', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 20),
              TextField(
                controller: heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Chiều cao (cm)',
                  prefixIcon: const Icon(Icons.height, color: AppTheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Cân nặng (kg)',
                  prefixIcon: const Icon(Icons.scale_outlined, color: AppTheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedGender,
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Nam')),
                  DropdownMenuItem(value: 'female', child: Text('Nữ')),
                  DropdownMenuItem(value: 'other', child: Text('Khác')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedGender = val);
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Giới tính',
                  prefixIcon: const Icon(Icons.wc_outlined, color: AppTheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final h = double.tryParse(heightController.text) ?? 0.0;
                          final w = double.tryParse(weightController.text) ?? 0.0;

                          if (h <= 0 || w <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('⚠️ Chiều cao và cân nặng phải lớn hơn 0'), backgroundColor: Colors.orangeAccent),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          final res = await ref.read(authProvider.notifier).updateProfile(
                                height: h,
                                weight: w,
                                gender: selectedGender,
                              );
                          setDialogState(() => isSaving = false);

                          if (res['success'] == true) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('🎯 Chỉ số sinh thể đã được cập nhật thành công!'), backgroundColor: Colors.green),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('❌ Cập nhật thất bại: ${res['message'] ?? 'Không rõ'}'), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Lưu thông tin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Đổi mật khẩu bảo mật', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 20),
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppTheme.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final oldP = oldPasswordController.text;
                          final newP = newPasswordController.text;

                          if (oldP.isEmpty || newP.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('⚠️ Vui lòng nhập đầy đủ mật khẩu cũ và mới'), backgroundColor: Colors.orangeAccent),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          // Gọi API đổi mật khẩu thông thường
                          final user = ref.read(authProvider).userData;
                          final userId = user?['id'] ?? user?['_id'] ?? '';
                          final apiService = ApiService();
                          
                          try {
                            final res = await apiService.changePassword(
                              userId: userId,
                              oldPassword: oldP,
                              newPassword: newP,
                            );
                            setDialogState(() => isSaving = false);
                            
                            if (res['success'] == true) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('🔑 Đổi mật khẩu thành công!'), backgroundColor: Colors.green),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('❌ Đổi mật khẩu thất bại: ${res['message'] ?? 'Không rõ'}'), backgroundColor: Colors.redAccent),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('❌ Lỗi kết nối: $e'), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Đổi mật khẩu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
