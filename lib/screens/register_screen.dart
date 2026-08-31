import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
import '../widgets/app_toast.dart';
import '../widgets/animated_icon_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiService _apiService = ApiService();

  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final birthDateController = TextEditingController();

  String? selectedGender;
  bool _loading = false;
  bool _hidePassword = true;
  bool _hideConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Responsive(
        mobile: _buildRegisterForm(context, widthFactor: 0.9, isMobile: true),
        tablet: _buildRegisterForm(context, maxWidth: 500, isMobile: false),
        desktop: _buildRegisterForm(context, maxWidth: 500, isMobile: false),
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context, {double? widthFactor, double? maxWidth, required bool isMobile}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.userPlus, size: 70, color: AppTheme.primary),
            const SizedBox(height: 16),
            
            Text(
              'Tạo tài khoản',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: isMobile ? 24 : 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tham gia cộng đồng HealthAI ngay hôm nay',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            Container(
              width: widthFactor != null ? MediaQuery.of(context).size.width * widthFactor : null,
              constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth) : null,
              child: Card(
                elevation: isMobile ? 1 : 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField("Họ và tên", nameController, LucideIcons.user),
                        const SizedBox(height: 16),

                        _buildTextField("Email", emailController, LucideIcons.mail, keyboard: TextInputType.emailAddress),
                        const SizedBox(height: 16),

                        // Layout Ngày sinh & Giới tính linh hoạt
                        isMobile 
                        ? Column(
                            children: [
                              _buildDatePicker(context),
                              const SizedBox(height: 16),
                              _buildGenderDropdown(),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(child: _buildDatePicker(context)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildGenderDropdown()),
                            ],
                          ),
                        const SizedBox(height: 16),

                        _buildPasswordField("Mật khẩu", passwordController, _hidePassword, () { setState(() => _hidePassword = !_hidePassword); }),
                        const SizedBox(height: 16),
                        
                        _buildPasswordField("Nhập lại mật khẩu", confirmPasswordController, _hideConfirm, () { setState(() => _hideConfirm = !_hideConfirm); }),
                        const SizedBox(height: 32),

                        _loading 
                          ? const Center(child: CircularProgressIndicator()) 
                          : ElevatedButton(
                              onPressed: _onRegister,
                              child: const Text('ĐĂNG KÝ'),
                            ),
                        
                        const SizedBox(height: 16),
                        
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Đã có tài khoản? Đăng nhập ngay'),
                          ),
                        ),
                      ],
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

  Widget _buildDatePicker(BuildContext context) {
    return TextFormField(
      controller: birthDateController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: "Ngày sinh",
        prefixIcon: Icon(LucideIcons.calendar),
      ),
      onTap: () async {
        DateTime? picked = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          birthDateController.text = "${picked.day}/${picked.month}/${picked.year}";
        }
      },
      validator: (val) => val == null || val.isEmpty ? "Vui lòng chọn ngày sinh" : null,
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: "Giới tính",
        prefixIcon: Icon(LucideIcons.users),
      ),
      value: selectedGender,
      items: const [
        DropdownMenuItem(value: "Nam", child: Text("Nam")),
        DropdownMenuItem(value: "Nữ", child: Text("Nữ")),
      ],
      onChanged: (val) => setState(() => selectedGender = val),
      validator: (val) => val == null ? "Chọn giới tính" : null,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      validator: (val) => val == null || val.isEmpty ? "Vui lòng nhập $label" : null,
    );
  }

  Widget _buildPasswordField(
      String label, TextEditingController controller, bool hide, VoidCallback toggle) {
    return TextFormField(
      controller: controller,
      obscureText: hide,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(LucideIcons.lock),
        suffixIcon: AnimatedIconButton(
          icon: hide ? LucideIcons.eyeOff : LucideIcons.eye,
          onPressed: toggle,
        ),
      ),
      validator: (val) => val == null || val.isEmpty ? "Vui lòng nhập $label" : null,
    );
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (passwordController.text != confirmPasswordController.text) {
      AppToast.show(context, message: "Mật khẩu nhập lại không khớp!", type: AppToastType.warning);
      return;
    }

    setState(() => _loading = true);

    final result = await _apiService.registerUser(
      name: nameController.text,
      email: emailController.text,
      password: passwordController.text,
      gender: selectedGender!,
      birthdate: birthDateController.text,
    );

    setState(() => _loading = false);

    if (result["success"] == true) {
      AppToast.show(context, message: "Đăng ký thành công! Hãy đăng nhập.", type: AppToastType.success);
      Navigator.pop(context);
    } else {
      AppToast.show(context, message: result["message"] ?? "Lỗi không xác định", type: AppToastType.error);
    }
  }
}
