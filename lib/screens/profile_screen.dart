import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../services/health_connect_service.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/health_provider.dart';
import 'terms_policy_screen.dart';
import 'user_guide_screen.dart';
import 'records_screen.dart';
import 'predict_screen.dart';
import 'admin_screen.dart';
import '../utils/health_calc.dart';
import '../widgets/app_toast.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String name;
  final String email;

  const ProfileScreen({Key? key, required this.name, required this.email}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Dùng cho việc đăng nhập lại Google Fit khi phiên hết hạn
  final dynamic _googleSignIn = GoogleSignIn(
    clientId: '457112627312-8hv3dglmk2eulk8ahl1ib3sg0hor1c1s.apps.googleusercontent.com',
    scopes: [
      'email',
      'https://www.googleapis.com/auth/fitness.activity.read',
      'https://www.googleapis.com/auth/fitness.body.read',
    ],
  );

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
                      if (userData?['role'] == 'admin') ...[
                        _buildSectionTitle("Quản trị"),
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(isDark ? 0.12 : 0.07),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            leading: const Icon(LucideIcons.shieldCheck, color: Colors.redAccent, size: 22),
                            title: const Text("Trang quản trị",
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.redAccent)),
                            trailing: const Icon(LucideIcons.chevronRight, size: 20, color: Colors.redAccent),
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      _buildSectionTitle("Sức khỏe & Mục tiêu"),
                      _buildListTile(
                        icon: LucideIcons.heartPulse,
                        title: "Hồ sơ sức khỏe (Cân nặng & BMI)",
                        isDark: isDark,
                        theme: theme,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RecordsScreen()),
                          );
                        },
                      ),
                      _buildListTile(
                        icon: LucideIcons.flag,
                        title: "Mục tiêu & Mức vận động",
                        isDark: isDark,
                        theme: theme,
                        onTap: () => _showGoalDialog(userData, isDark, theme),
                      ),
                      _buildListTile(
                        icon: LucideIcons.trendingUp,
                        title: "Dự đoán calo tiêu hao (AI/ML)",
                        isDark: isDark,
                        theme: theme,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PredictScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Thiết bị & Dữ liệu"),
                      _buildListTile(
                        icon: LucideIcons.refreshCw,
                        title: "Đồng bộ Google Fit ngay",
                        isDark: isDark,
                        theme: theme,
                        onTap: _handleGoogleFitSync,
                      ),
                      _buildListTile(
                        icon: LucideIcons.stethoscope,
                        title: "Kiểm tra Health Connect (dự phòng)",
                        isDark: isDark,
                        theme: theme,
                        onTap: _testHealthConnect,
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Tùy chọn"),
                      _buildListTile(
                        icon: LucideIcons.moon,
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
                        icon: LucideIcons.lock,
                        title: "Đổi mật khẩu",
                        isDark: isDark,
                        theme: theme,
                        onTap: () => _showChangePasswordDialog(isDark, theme),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Hỗ trợ & Thông tin"),
                      _buildListTile(
                        icon: LucideIcons.circleHelp,
                        title: "Hướng dẫn sử dụng",
                        isDark: isDark,
                        theme: theme,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const UserGuideScreen()),
                          );
                        },
                      ),
                      _buildListTile(
                        icon: LucideIcons.fileText,
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
                        icon: LucideIcons.messageSquare,
                        title: "Đóng góp ý kiến",
                        isDark: isDark,
                        theme: theme,
                        onTap: () => _showFeedbackDialog(isDark, theme),
                      ),
                      _buildListTile(
                        icon: LucideIcons.info,
                        title: "Phiên bản ứng dụng",
                        isDark: isDark,
                        theme: theme,
                        trailing: Text(
                          "v1.2.0",
                          style: TextStyle(
                            color: isDark ? const Color(0xFF949BA4) : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSectionTitle("Vùng nguy hiểm"),
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(isDark ? 0.12 : 0.07),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          leading: const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 22),
                          title: const Text("Xóa tài khoản",
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.redAccent)),
                          trailing: const Icon(LucideIcons.chevronRight, size: 20, color: Colors.redAccent),
                          onTap: _showDeleteAccountDialog,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.22 : 0.055),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: AppTheme.primary,
              child: Icon(LucideIcons.user, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 19,
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
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.pencil, color: AppTheme.primary, size: 18),
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
        children: [
          _buildBiometricRow(LucideIcons.ruler, "Chiều cao", height > 0 ? "${height.toStringAsFixed(0)} cm" : "-- cm", isDark),
          Divider(height: 24, color: theme.dividerColor),
          _buildBiometricRow(LucideIcons.scale, "Cân nặng", weight > 0 ? "${weight.toStringAsFixed(1)} kg" : "-- kg", isDark),
          Divider(height: 24, color: theme.dividerColor),
          _buildBiometricRow(LucideIcons.calendar, "Tuổi", age > 0 ? "$age tuổi" : "-- tuổi", isDark),
          Divider(height: 24, color: theme.dividerColor),
          _buildBiometricRow(LucideIcons.users, "Giới tính", genderText, isDark),
          Divider(height: 24, color: theme.dividerColor),
          _buildBiometricRow(LucideIcons.heart, "Chỉ số BMI", bmi > 0 ? bmi.toStringAsFixed(1) : "--", isDark, valueColor: Colors.blueAccent),
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
            fontSize: 14,
            color: isDark ? const Color(0xFFB5BAC1) : Colors.black54,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? const Color(0xFFF2F3F5) : Colors.black87),
            fontSize: 16,
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
          fontSize: 14,
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.055),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(icon, color: AppTheme.primary, size: 22),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: isDark ? const Color(0xFFF2F3F5) : Colors.black87,
          ),
        ),
        trailing: trailing ?? Icon(LucideIcons.chevronRight, size: 20, color: isDark ? const Color(0xFF949BA4) : Colors.grey),
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
        icon: const Icon(LucideIcons.logOut, size: 20),
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

    final nameController = TextEditingController(text: userData?['name']?.toString() ?? '');
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
                'Chỉnh sửa hồ sơ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFF2F3F5) : Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                style: TextStyle(color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Tên hiển thị',
                  prefixIcon: Icon(LucideIcons.idCard, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Chiều cao (cm)',
                  prefixIcon: Icon(LucideIcons.ruler, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Cân nặng (kg)',
                  prefixIcon: Icon(LucideIcons.scale, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ageController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Tuổi',
                  prefixIcon: Icon(LucideIcons.calendar, color: AppTheme.primary),
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
                  prefixIcon: Icon(LucideIcons.users, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 24),
              PurpleGradientButton(
                height: 52,
                onPressed: isSaving
                    ? () {}
                    : () async {
                        final name = nameController.text.trim();
                        final h = double.tryParse(heightController.text) ?? 0.0;
                        final w = double.tryParse(weightController.text) ?? 0.0;
                        final ageVal = int.tryParse(ageController.text) ?? 0;

                        if (name.length < 2) {
                          AppToast.show(
                            context,
                            message: 'Tên phải có ít nhất 2 ký tự',
                            type: AppToastType.warning,
                          );
                          return;
                        }
                        if (h <= 0 || w <= 0 || ageVal <= 0) {
                          AppToast.show(
                            context,
                            message: 'Chiều cao, cân nặng và tuổi phải lớn hơn 0',
                            type: AppToastType.warning,
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        final res = await ApiService().updateProfileFields({
                          'name': name,
                          'height': h,
                          'weight': w,
                          'gender': selectedGender,
                          'age': ageVal,
                        });
                        await ref.read(authProvider.notifier).refreshUserData();
                        // Refresh health state BMI/Weight trends reactively
                        await ref.read(healthProvider.notifier).refreshAll();
                        setDialogState(() => isSaving = false);

                        if (res['success'] == true) {
                          Navigator.pop(context);
                          AppToast.show(
                            context,
                            message: 'Hồ sơ đã được cập nhật thành công!',
                            type: AppToastType.success,
                          );
                        } else {
                          AppToast.show(
                            context,
                            message: 'Cập nhật thất bại: ${res['message'] ?? 'Không rõ'}',
                            type: AppToastType.error,
                          );
                        }
                      },
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Lưu thông tin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Đồng bộ Google Fit thật (báo kết quả trung thực) ---
  Future<void> _handleGoogleFitSync() async {
    final userData = ref.read(authProvider).userData;
    final userId = (userData?['id'] ?? userData?['_id'] ?? '').toString();
    if (userId.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final result = await ApiService().syncGoogleFit(userId: userId);
      await ref.read(healthProvider.notifier).refreshAll();
      if (!mounted) return;
      Navigator.pop(context);
      final data = result['data'] ?? {};
      final steps = data['steps'] ?? 0;
      final cal = (data['caloriesBurned'] ?? 0);
      AppToast.show(
        context,
        message: 'Đồng bộ Google Fit: $steps bước • ${(cal as num).toStringAsFixed(0)} kcal',
        type: AppToastType.success,
      );
    } catch (e) {
      // Google Fit lỗi (hết hạn / API ngừng hoạt động) — thử Health Connect/HealthKit
      // trên thiết bị trước khi báo lỗi cho người dùng.
      try {
        final fallback = await HealthConnectService().fetchToday();
        if (fallback != null) {
          final result = await ApiService().syncHealthConnect(
            userId: userId,
            steps: fallback.steps,
            caloriesBurned: fallback.caloriesBurned,
          );
          await ref.read(healthProvider.notifier).refreshAll();
          if (!mounted) return;
          Navigator.pop(context);
          final data = result['data'] ?? {};
          AppToast.show(
            context,
            message: 'Đồng bộ qua Health Connect: ${data['steps'] ?? 0} bước • ${((data['caloriesBurned'] ?? 0) as num).toStringAsFixed(0)} kcal',
            type: AppToastType.success,
          );
          return;
        }
      } catch (_) {
        // Không có Health Connect / bị từ chối quyền — rơi xuống cảnh báo Google Fit bên dưới
      }

      if (!mounted) return;
      Navigator.pop(context);
      // Phiên hết hạn → cho nút đăng nhập lại Google ngay trên snackbar (có action, giữ nguyên SnackBar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('⚠️ Phiên Google Fit đã hết hạn hoặc chưa cấp quyền.'),
          backgroundColor: Colors.orangeAccent,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'ĐĂNG NHẬP LẠI',
            textColor: Colors.white,
            onPressed: _reloginGoogleFit,
          ),
        ),
      );
    }
  }

  // --- Đăng nhập lại Google để lấy token mới rồi đồng bộ lại ---
  Future<void> _reloginGoogleFit() async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
      // Đăng xuất phiên Google cũ để buộc chọn tài khoản & cấp token mới
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      final dynamic googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        if (mounted) Navigator.pop(context);
        return; // người dùng hủy
      }
      final dynamic googleAuth = await googleUser.authentication;
      final userData = ref.read(authProvider).userData;
      final userId = (userData?['id'] ?? userData?['_id'] ?? '').toString();

      final result = await ApiService().syncGoogleFit(
        userId: userId,
        accessToken: googleAuth.accessToken ?? googleAuth.idToken,
      );
      await ref.read(healthProvider.notifier).refreshAll();
      if (!mounted) return;
      Navigator.pop(context);
      final data = result['data'] ?? {};
      AppToast.show(
        context,
        message: 'Đã kết nối lại Google Fit: ${data['steps'] ?? 0} bước • ${((data['caloriesBurned'] ?? 0) as num).toStringAsFixed(0)} kcal',
        type: AppToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      AppToast.show(
        context,
        message: 'Đăng nhập lại thất bại: $e',
        type: AppToastType.error,
      );
    }
  }

  // --- TEST: kiểm tra riêng đường Health Connect/HealthKit, không liên quan Google Fit ---
  // Gọi thẳng runDiagnostic() (không đợi Google Fit thất bại trước) để bạn tự xác
  // minh trên máy thật xem đường dự phòng có đọc được dữ liệu không, và nếu không
  // thì biết chính xác đang vướng ở bước nào.
  Future<void> _testHealthConnect() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final diag = await HealthConnectService().runDiagnostic();
    if (!mounted) return;
    Navigator.pop(context);

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              diag.success ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
              color: diag.success ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 10),
            const Expanded(child: Text('Kiểm tra Health Connect')),
          ],
        ),
        content: Text(
          diag.success
              ? 'Đọc thành công!\n\nBước chân hôm nay: ${diag.steps}\nCalo tiêu hao: ${diag.caloriesBurned?.toStringAsFixed(0)} kcal\n\n(Đây là dữ liệu thật lấy từ Health Connect/HealthKit trên máy bạn — không liên quan gì tới Google Fit.)'
              : (diag.errorMessage ?? 'Không đọc được dữ liệu, không rõ lý do.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
        ],
      ),
    );
  }

  // --- Đặt mục tiêu & mức vận động ---
  void _showGoalDialog(Map<String, dynamic>? userData, bool isDark, ThemeData theme) {
    String goal = userData?['goal']?.toString() ?? 'maintain';
    String activity = userData?['activityLevel']?.toString() ?? 'light';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mục tiêu & Mức vận động',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87)),
              const SizedBox(height: 8),
              Text('Dùng để tính mục tiêu calo nạp mỗi ngày của bạn.', style: TextStyle(color: theme.hintColor, fontSize: 13)),
              const SizedBox(height: 20),
              Text('Mục tiêu', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: HealthCalc.goalLabels.entries.map((e) {
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: goal == e.key,
                    selectedColor: AppTheme.primary,
                    labelStyle: TextStyle(color: goal == e.key ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                    onSelected: (_) => setDialogState(() => goal = e.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text('Mức độ vận động', style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black87)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: activity,
                dropdownColor: theme.cardColor,
                isExpanded: true,
                style: TextStyle(color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                items: HealthCalc.activityLabels.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (v) => setDialogState(() => activity = v ?? 'light'),
                decoration: const InputDecoration(prefixIcon: Icon(LucideIcons.activity, color: AppTheme.primary)),
              ),
              const SizedBox(height: 24),
              PurpleGradientButton(
                height: 52,
                onPressed: isSaving
                    ? () {}
                    : () async {
                        setDialogState(() => isSaving = true);
                        final res = await ApiService().updateProfileFields({'goal': goal, 'activityLevel': activity});
                        await ref.read(authProvider.notifier).refreshUserData();
                        await ref.read(healthProvider.notifier).refreshAll();
                        if (!mounted) return;
                        setDialogState(() => isSaving = false);
                        Navigator.pop(context);
                        AppToast.show(
                          context,
                          message: res['success'] == true ? 'Đã cập nhật mục tiêu!' : (res['message'] ?? 'Lỗi'),
                          type: res['success'] == true ? AppToastType.success : AppToastType.error,
                        );
                      },
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Lưu mục tiêu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Xóa tài khoản (2 bước xác nhận) ---
  Future<void> _showDeleteAccountDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: const Text(
          'Toàn bộ dữ liệu của bạn (bữa ăn, hoạt động, chỉ số, hội thoại AI) sẽ bị xóa vĩnh viễn và KHÔNG THỂ khôi phục. Bạn có chắc chắn?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final res = await ApiService().deleteAccount();
    if (!mounted) return;
    Navigator.pop(context); // đóng loading
    if (res['success'] == true) {
      await ref.read(authProvider.notifier).logout();
    } else {
      AppToast.show(
        context,
        message: res['message'] ?? 'Xóa thất bại',
        type: AppToastType.error,
      );
    }
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
                  prefixIcon: Icon(LucideIcons.lock, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                style: TextStyle(color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu mới',
                  prefixIcon: Icon(LucideIcons.keyRound, color: AppTheme.primary),
                ),
              ),
              const SizedBox(height: 24),
              PurpleGradientButton(
                height: 52,
                onPressed: isSaving
                    ? () {}
                    : () async {
                        final oldP = oldPasswordController.text;
                        final newP = newPasswordController.text;

                        if (oldP.isEmpty || newP.isEmpty) {
                          AppToast.show(
                            context,
                            message: 'Vui lòng nhập đầy đủ mật khẩu cũ và mới',
                            type: AppToastType.warning,
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
                            AppToast.show(
                              context,
                              message: 'Đổi mật khẩu thành công!',
                              type: AppToastType.success,
                            );
                          } else {
                            AppToast.show(
                              context,
                              message: 'Đổi mật khẩu thất bại: ${res['message'] ?? 'Không rõ'}',
                              type: AppToastType.error,
                            );
                          }
                        } catch (e) {
                          setDialogState(() => isSaving = false);
                          AppToast.show(
                            context,
                            message: 'Lỗi kết nối: $e',
                            type: AppToastType.error,
                          );
                        }
                      },
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Đổi mật khẩu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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
                    child: Icon(LucideIcons.squarePen, color: AppTheme.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              PurpleGradientButton(
                height: 52,
                onPressed: isSaving
                    ? () {}
                    : () async {
                        final text = feedbackController.text.trim();
                        if (text.isEmpty) {
                          AppToast.show(
                            context,
                            message: 'Vui lòng nhập nội dung góp ý',
                            type: AppToastType.warning,
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        final apiService = ApiService();
                        final res = await apiService.submitFeedback(content: text);
                        setDialogState(() => isSaving = false);

                        if (mounted) {
                          Navigator.pop(context);
                          if (res['success'] == true) {
                            AppToast.show(
                              context,
                              message: res['message'] ?? 'Cảm ơn bạn đã đóng góp ý kiến! Phản hồi đã được ghi nhận.',
                              type: AppToastType.success,
                            );
                          } else {
                            AppToast.show(
                              context,
                              message: 'Gửi phản hồi thất bại: ${res['message'] ?? 'Không rõ lý do'}',
                              type: AppToastType.error,
                            );
                          }
                        }
                      },
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Gửi phản hồi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
