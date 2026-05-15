import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../utils/responsive.dart';
import 'register_screen.dart';
import 'main_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen(userData: response["user"])));
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
            const SizedBox(height: 32),
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
      decoration: InputDecoration(
        labelText: label,
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

  Future<void> _login() async {
    setState(() => _isLoading = true);
    final response = await _apiService.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    setState(() => _isLoading = false);
    if (response["success"] == true) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => MainScreen(userData: response["user"])));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response["message"] ?? "Lỗi đăng nhập")));
    }
  }
}
