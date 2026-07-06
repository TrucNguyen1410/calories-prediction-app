import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/responsive.dart';
import 'register_screen.dart';
import 'main_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Cấu hình GoogleSignIn - Pass clientId trực tiếp để tránh lỗi invalid_client
  final dynamic _googleSignIn = GoogleSignIn(
    // BẠN CẦN THAY CHUỖI NÀY BẰNG CLIENT ID THẬT CỦA BẠN TRÊN GOOGLE CLOUD
    clientId: '457112627312-8hv3dglmk2eulk8ahl1ib3sg0hor1c1s.apps.googleusercontent.com',
    scopes: [
      'email',
      'https://www.googleapis.com/auth/fitness.activity.read',
      'https://www.googleapis.com/auth/fitness.body.read',
    ],
  );

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);
      final dynamic googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final dynamic googleAuth = await googleUser.authentication;
      final response = await _apiService.loginUser(
        email: googleUser.email,
        password: 'GOOGLE_AUTH_EXTERNAL', 
      );
      if (response["success"] == true) {
        await _apiService.syncGoogleFit(
          userId: response["user"]["id"] ?? response["user"]["_id"],
          accessToken: googleAuth.accessToken ?? googleAuth.idToken,
        );
        if (mounted) {
          await ref.read(authProvider.notifier).loginWithGoogle(response["user"], response["token"]);
        }
      }
      setState(() => _isLoading = false);
    } catch (error) {
      setState(() => _isLoading = false);
      print('Google Sign-In Error Detail: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi đăng nhập Google: $error. Hãy kiểm tra ClientID và Origin URL.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE0F2F1), Color(0xFFFFFFFF), Color(0xFFE1F5FE)],
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Responsive(
                mobile: _buildLoginCard(context, isMobile: true),
                tablet: _buildLoginCard(context, maxWidth: 450, isMobile: false),
                desktop: _buildLoginCard(context, maxWidth: 450, isMobile: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context, {double? maxWidth, required bool isMobile}) {
    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 60, color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text(
              'HealthAI',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordController,
              label: 'Mật khẩu',
              icon: Icons.lock_outline,
              isPassword: true,
              obscureText: _obscurePassword,
              onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _showForgotPasswordDialog,
                child: const Text('Quên mật khẩu?', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
            _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _login,
                          child: const Text('ĐĂNG NHẬP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('hoặc', style: TextStyle(color: Colors.grey, fontSize: 12))),
                          Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.grey.shade300),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: _handleGoogleSignIn,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FaIcon(FontAwesomeIcons.google, color: Colors.red, size: 20),
                              SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  'Tiếp tục bằng Google',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Bạn mới sử dụng?', style: TextStyle(color: Colors.grey[600])),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                  child: const Text('Đăng ký ngay', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      // Thẻ đăng nhập luôn nền sáng nên ép chữ màu tối để không bị "tàng hình" ở Dark Mode
      style: const TextStyle(color: Colors.black87),
      cursorColor: AppTheme.primary,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600),
        floatingLabelStyle: const TextStyle(color: AppTheme.primary),
        prefixIcon: Icon(icon, color: AppTheme.primary.withOpacity(0.7)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }

  // --- Luồng quên mật khẩu bằng OTP email ---
  Future<void> _showForgotPasswordDialog() async {
    final emailController = TextEditingController(text: _emailController.text.trim());
    final otpController = TextEditingController();
    final newPassController = TextEditingController();
    bool otpSent = false;
    bool busy = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(otpSent ? 'Đặt lại mật khẩu' : 'Quên mật khẩu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!otpSent) ...[
                  const Text('Nhập email tài khoản, chúng tôi sẽ gửi mã OTP để đặt lại mật khẩu.',
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
                  ),
                ] else ...[
                  Text('Nhập mã OTP đã gửi tới ${emailController.text} và mật khẩu mới.',
                      style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(labelText: 'Mã OTP (6 số)', prefixIcon: Icon(Icons.pin_outlined)),
                  ),
                  TextField(
                    controller: newPassController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mật khẩu mới', prefixIcon: Icon(Icons.lock_outline)),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
            ElevatedButton(
              onPressed: busy
                  ? null
                  : () async {
                      setDialogState(() => busy = true);
                      if (!otpSent) {
                        final res = await _apiService.forgotPassword(emailController.text.trim());
                        setDialogState(() {
                          busy = false;
                          otpSent = res['success'] == true;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(res['message'] ?? '')),
                          );
                        }
                      } else {
                        final res = await _apiService.resetPassword(
                          email: emailController.text.trim(),
                          otp: otpController.text.trim(),
                          newPassword: newPassController.text,
                        );
                        setDialogState(() => busy = false);
                        if (res['success'] == true) {
                          if (mounted) Navigator.pop(ctx);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(res['message'] ?? ''),
                              backgroundColor: res['success'] == true ? Colors.green : Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(otpSent ? 'Đặt lại' : 'Gửi OTP'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final response = await ref.read(authProvider.notifier).login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() => _isLoading = false);
    if (response["success"] == true) {
      // Riverpod automatically handles switching home to MainScreen, no Navigator.push needed!
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response["message"] ?? "Lỗi đăng nhập")));
    }
  }
}
