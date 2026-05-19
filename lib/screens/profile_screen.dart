import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/health_provider.dart';
import 'terms_policy_screen.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);
    final isDarkEnabled = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cá nhân", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(userData, isDark),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Thông số sinh thể"),
                      _buildBiometricDetailsCard(userData, isDark, theme),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Cá nhân hóa"),
                      _buildListTile(
                        icon: Icons.dark_mode_outlined,
                        title: "Chế độ tối (Dark Mode)",
                        isDark: isDark,
                        theme: theme,
                        trailing: Switch(
                          value: isDarkEnabled,
                          onChanged: (val) {
                            ref.read(themeProvider.notifier).toggleTheme();
                          },
                          activeColor: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Tài khoản & Bảo mật"),
                      _buildListTile(
                        icon: Icons.lock_outline,
                        title: "Đổi mật khẩu",
                        isDark: isDark,
                        theme: theme,
                        onTap: () => _showChangePasswordDialog(isDark, theme),
                      ),
                      _buildListTile(
                        icon: Icons.sync_lock,
                        title: "Đồng bộ Google Fit",
                        isDark: isDark,
                        theme: theme,
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
                      const SizedBox(height: 24),
                      _buildSectionTitle("Hỗ trợ & Thông tin"),
                      _buildListTile(
                        icon: Icons.description_outlined,
                        title: "Điều khoản & Chính sách",
                        isDark: isDark,
                        theme: theme,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TermsPolicyScreen()),
                          );
                        },
                      ),
                      _buildListTile(
                        icon: Icons.feedback_outlined,
                        title: "Đóng góp ý kiến",
                        isDark: isDark,
                        theme: theme,
                        onTap: () => _showFeedbackDialog(isDark, theme),
                      ),
                      _buildListTile(
                        icon: Icons.info_outline,
                        title: "Phiên bản ứng dụng",
                        isDark: isDark,
                        theme: theme,
                        trailing: Text(
                          "v1.0.0",
                          style: TextStyle(
                            color: isDark ? const Color(0xFF949BA4) : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildLogoutButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic>? userData, bool isDark) {
    final displayName = userData?['name'] ?? widget.name;
    final displayEmail = userData?['email'] ?? widget.email;

    return InkWell(
      onTap: () => _showEditProfileDialog(userData, isDark),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
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
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFF2F3F5) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    displayEmail,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF949BA4) : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
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

  Widget _buildBiometricDetailsCard(Map<String, dynamic>? userData, bool isDark, ThemeData theme) {
    final height = (userData?['height'] ?? 0.0).toDouble();
    final weight = (userData?['weight'] ?? 0.0).toDouble();
    final gender = userData?['gender'] ?? 'Chưa xác định';
    
    int age = 0;
    if (userData?['dob'] != null) {
      try {
        final dob = DateTime.parse(userData!['dob'].toString());
        age = DateTime.now().year - dob.year;
      } catch (_) {}
    }

    final heightM = height / 100.0;
    final bmi = (height > 0 && weight > 0) ? weight / (heightM * heightM) : 0.0;

    String genderText = 'Chưa xác định';
    if (gender == 'male' || gender == 'Nam') {
      genderText = 'Nam';
    } else if (gender == 'female' || gender == 'Nữ') {
      genderText = 'Nữ';
    } else if (gender == 'other' || gender == 'Khác') {
      genderText = 'Khác';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _buildBiometricRow(Icons.height, "Chiều cao", height > 0 ? "${height.toStringAsFixed(0)} cm" : "-- cm", isDark),
          Divider(height: 24, color: theme.dividerColor),
          _buildBiometricRow(Icons.scale_outlined, "Cân nặng", weight > 0 ? "${weight.toStringAsFixed(1)} kg" : "-- kg", isDark),
          Divider(height: 24, color: theme.dividerColor),
          _buildBiometricRow(Icons.calendar_today_outlined, "Tuổi", age > 0 ? "$age tuổi" : "-- tuổi", isDark),
          Divider(height: 24, color: theme.dividerColor),
          _buildBiometricRow(Icons.wc_outlined, "Giới tính", genderText, isDark),
          Divider(height: 24, color: theme.dividerColor),
          _buildBiometricRow(Icons.favorite_outline, "Chỉ số BMI", bmi > 0 ? bmi.toStringAsFixed(1) : "--", isDark, valueColor: Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildBiometricRow(IconData icon, String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFB5BAC1) : Colors.black54,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? const Color(0xFFF2F3F5) : Colors.black87),
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF949BA4) : Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required bool isDark,
    required ThemeData theme,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFF2F3F5) : Colors.black87,
          ),
        ),
        trailing: trailing ?? Icon(Icons.chevron_right, color: isDark ? const Color(0xFF949BA4) : Colors.grey),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(20),
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

  void _showEditProfileDialog(Map<String, dynamic>? userData, bool isDark) {
    final height = (userData?['height'] ?? 0.0).toDouble();
    final weight = (userData?['weight'] ?? 0.0).toDouble();
    final gender = userData?['gender'] ?? 'Nam';
    
    int age = 0;
    if (userData?['dob'] != null) {
      try {
        final dob = DateTime.parse(userData!['dob'].toString());
        age = DateTime.now().year - dob.year;
      } catch (_) {}
    }

    final weightController = TextEditingController(text: weight > 0 ? weight.toString() : '');
    final heightController = TextEditingController(text: height > 0 ? height.toString() : '');
    final ageController = TextEditingController(text: age > 0 ? age.toString() : '');

    String selectedGender = 'Nam';
    if (gender == 'male' || gender == 'Nam') {
      selectedGender = 'Nam';
    } else if (gender == 'female' || gender == 'Nữ') {
      selectedGender = 'Nữ';
    } else if (gender == 'other' || gender == 'Khác') {
      selectedGender = 'Khác';
    }

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
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
              Text(
                'Cập nhật thông tin cơ bản',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF2F3F5) : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Chiều cao (cm)',
                  prefixIcon: Icon(Icons.height, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Cân nặng (kg)',
                  prefixIcon: Icon(Icons.scale_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Tuổi',
                  prefixIcon: Icon(Icons.calendar_today_outlined, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedGender,
                dropdownColor: Theme.of(context).cardColor,
                style: TextStyle(color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                items: const [
                  DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                  DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                  DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedGender = val);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Giới tính',
                  prefixIcon: Icon(Icons.wc_outlined, color: AppTheme.primary),
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
                          final ageVal = int.tryParse(ageController.text) ?? 0;

                          if (h <= 0 || w <= 0 || ageVal <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('⚠️ Chiều cao, cân nặng và tuổi phải lớn hơn 0'), backgroundColor: Colors.orangeAccent),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          final res = await ref.read(authProvider.notifier).updateProfile(
                                height: h,
                                weight: w,
                                gender: selectedGender,
                                age: ageVal,
                              );
                          
                          // Refresh health state BMI/Weight trends reactively
                          await ref.read(healthProvider.notifier).refreshAll();
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

  void _showChangePasswordDialog(bool isDark, ThemeData theme) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
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
              Text(
                'Đổi mật khẩu bảo mật',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF2F3F5) : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: oldPasswordController,
                obscureText: true,
                style: TextStyle(color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu hiện tại',
                  prefixIcon: Icon(Icons.lock_outline, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                style: TextStyle(color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: Icon(Icons.vpn_key_outlined, color: AppTheme.primary),
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

  void _showFeedbackDialog(bool isDark, ThemeData theme) {
    final feedbackController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
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
              Text(
                'Đóng góp ý kiến',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF2F3F5) : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ý kiến đóng góp của bạn sẽ giúp chúng tôi cải thiện HealthAI tốt hơn mỗi ngày.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF949BA4) : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: feedbackController,
                maxLines: 4,
                style: TextStyle(color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Nội dung phản hồi',
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 50),
                    child: Icon(Icons.edit_note_outlined, color: AppTheme.primary),
                  ),
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
                          final text = feedbackController.text.trim();
                          if (text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('⚠️ Vui lòng nhập nội dung góp ý'), backgroundColor: Colors.orangeAccent),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);
                          // Giả lập gửi feedback thành công
                          await Future.delayed(const Duration(milliseconds: 800));
                          setDialogState(() => isSaving = false);

                          if (mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('💖 Cảm ơn bạn đã đóng góp ý kiến! Phản hồi đã được ghi nhận.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Gửi phản hồi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
