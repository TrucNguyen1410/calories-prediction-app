import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';

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
      backgroundColor: const Color(0xFFF7FBFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 56, bottom: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFBEE7FF), Color(0xFFDFF3FF)],
                ),
              ),
              child: Column(
                children: const [
                  Icon(Icons.person_add, size: 60, color: AppTheme.primaryDark),
                  SizedBox(height: 8),
                  Text('Tạo tài khoản', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryDark)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField("Họ và tên", nameController),
                      const SizedBox(height: 12),
                      _buildPasswordField("Mật khẩu", passwordController, _hidePassword, () { setState(() => _hidePassword = !_hidePassword); }),
                      const SizedBox(height: 12),
                      _buildPasswordField("Nhập lại mật khẩu", confirmPasswordController, _hideConfirm, () { setState(() => _hideConfirm = !_hideConfirm); }),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: birthDateController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: "Ngày sinh",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF3A8DFF)),
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
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: "Giới tính",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              value: selectedGender,
                              items: const [DropdownMenuItem(value: "Nam", child: Text("Nam")), DropdownMenuItem(value: "Nữ", child: Text("Nữ"))],
                              onChanged: (val) => setState(() => selectedGender = val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTextField("Email", emailController, keyboard: TextInputType.emailAddress),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryDark,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          onPressed: _loading ? null : _onRegister,
                          child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('ĐĂNG KÝ', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboard = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: IconButton(
          icon: Icon(hide ? Icons.visibility_off : Icons.visibility),
          onPressed: toggle,
        ),
      ),
      validator: (val) => val == null || val.isEmpty ? "Vui lòng nhập $label" : null,
    );
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;
    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Mật khẩu nhập lại không khớp!")));
      return;
    }
    if (selectedGender == null || birthDateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng chọn ngày sinh và giới tính")));
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Đăng ký thành công!")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result["message"] ?? "Lỗi không xác định")));
    }
  }
}
