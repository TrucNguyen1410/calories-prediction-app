import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';
import '../providers/health_provider.dart';
import '../utils/health_calc.dart';
import '../theme.dart';

/// Màn hình thiết lập ban đầu — thu thập chỉ số & mục tiêu ngay sau khi đăng ký,
/// giúp cá nhân hóa mục tiêu calo (TDEE) và tránh dữ liệu trống (weight = 0).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _gender = 'Nam';
  String _goal = 'maintain';
  String _activity = 'light';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).userData;
    if (user?['gender'] != null && ['Nam', 'Nữ', 'Khác'].contains(user!['gender'])) {
      _gender = user['gender'];
    }
    if ((user?['height'] ?? 0) > 0) _heightController.text = user!['height'].toString();
    if ((user?['weight'] ?? 0) > 0) _weightController.text = user!['weight'].toString();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final result = await ApiService().updateProfileFields({
      'height': double.parse(_heightController.text),
      'weight': double.parse(_weightController.text),
      'gender': _gender,
      'goal': _goal,
      'activityLevel': _activity,
      'onboarded': true,
    });

    if (!mounted) return;

    if (result['success'] == true) {
      await ref.read(authProvider.notifier).refreshUserData();
      await ref.read(healthProvider.notifier).refreshAll();
      // main.dart sẽ tự chuyển sang MainScreen khi onboarded = true
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Lỗi lưu thông tin'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    const Icon(Icons.favorite, color: AppTheme.primary, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      "Chào mừng đến với HealthAI!",
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Cho chúng tôi biết một vài thông tin để cá nhân hóa mục tiêu calo và kế hoạch sức khỏe của bạn.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.hintColor),
                    ),
                    const SizedBox(height: 28),

                    // Giới tính
                    _label("Giới tính"),
                    Row(
                      children: ['Nam', 'Nữ', 'Khác'].map((g) {
                        final selected = _gender == g;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: SizedBox(width: double.infinity, child: Text(g, textAlign: TextAlign.center)),
                              selected: selected,
                              onSelected: (_) => setState(() => _gender = g),
                              selectedColor: AppTheme.primary,
                              labelStyle: TextStyle(color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    _label("Chiều cao (cm)"),
                    TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.height), hintText: "VD: 170"),
                      validator: (v) {
                        final d = double.tryParse(v ?? '');
                        if (d == null || d < 50 || d > 260) return "Nhập chiều cao 50 - 260 cm";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _label("Cân nặng (kg)"),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.scale), hintText: "VD: 65"),
                      validator: (v) {
                        final d = double.tryParse(v ?? '');
                        if (d == null || d < 20 || d > 400) return "Nhập cân nặng 20 - 400 kg";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _label("Mục tiêu của bạn"),
                    Row(
                      children: HealthCalc.goalLabels.entries.map((e) {
                        final selected = _goal == e.key;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: SizedBox(width: double.infinity, child: Text(e.value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                              selected: selected,
                              onSelected: (_) => setState(() => _goal = e.key),
                              selectedColor: AppTheme.primary,
                              labelStyle: TextStyle(color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    _label("Mức độ vận động"),
                    DropdownButtonFormField<String>(
                      value: _activity,
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.directions_run)),
                      items: HealthCalc.activityLabels.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => setState(() => _activity = v ?? 'light'),
                    ),
                    const SizedBox(height: 28),

                    ElevatedButton(
                      onPressed: _saving ? null : _finish,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text("BẮT ĐẦU", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 4),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
      );
}
