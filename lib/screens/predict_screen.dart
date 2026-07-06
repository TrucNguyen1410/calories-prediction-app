import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/api_service.dart';
import '../utils/responsive.dart';
import '../utils/health_calc.dart';
import '../theme.dart';
import 'history_screen.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({Key? key}) : super(key: key);

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();

  final List<String> _activities = ["Gym", "Chạy bộ", "Đạp xe", "Bơi lội", "Yoga", "Leo núi", "Đi bộ nhanh"];
  String? _selectedActivity;
  double? _predictedCalories;
  bool _isLoading = false;
  bool _prefilledFromProfile = false;

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  // Tự động điền cân nặng/chiều cao/tuổi từ hồ sơ người dùng để đỡ phải nhập tay
  Future<void> _prefillFromProfile() async {
    final user = await _apiService.getUserData();
    if (user == null || !mounted) return;

    final weight = (user['weight'] ?? 0).toDouble();
    final height = (user['height'] ?? 0).toDouble();
    final age = HealthCalc.ageFromDob(user['dob']);

    setState(() {
      if (weight > 0) _weightController.text = weight.toStringAsFixed(weight % 1 == 0 ? 0 : 1);
      if (height > 0) _heightController.text = height.toStringAsFixed(0);
      _ageController.text = age.toString();
      // Nhịp tim trung bình khi tập ~120 bpm — điền sẵn giá trị gợi ý, người dùng có thể sửa
      if (_heartRateController.text.isEmpty) _heartRateController.text = '120';
      _prefilledFromProfile = weight > 0 || height > 0;
    });
  }

  Future<void> _predictCalories() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final workout = Workout(
      activityType: _selectedActivity ?? "Không xác định",
      weight: double.tryParse(_weightController.text) ?? 0,
      height: double.tryParse(_heightController.text) ?? 0,
      age: int.tryParse(_ageController.text) ?? 0,
      duration: int.tryParse(_durationController.text) ?? 0,
      heartRate: int.tryParse(_heartRateController.text) ?? 0,
      calories: 0,
      date: DateTime.now().toIso8601String(),
    );

    final result = await _apiService.predictCalories(workout);
    setState(() {
      _isLoading = false;
      _predictedCalories = result;
    });

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('❌ Dự đoán thất bại'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dự đoán Calo"),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 900),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildHeader(),
                  if (_prefilledFromProfile) ...[
                    const SizedBox(height: 12),
                    _buildPrefillNote(),
                  ],
                  const SizedBox(height: 32),
                  Responsive(
                    mobile: _buildFormLayout(isMobile: true),
                    tablet: _buildFormLayout(isMobile: false),
                    desktop: _buildFormLayout(isMobile: false),
                  ),
                  const SizedBox(height: 32),
                  _buildPredictButton(),
                  if (_predictedCalories != null) _buildResultCard(),
                  const SizedBox(height: 24),
                  _buildHistoryButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.primary,
            child: Icon(Icons.auto_graph, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dự đoán Calo tiêu hao', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18)),
                Text('Nhập thông tin buổi tập để AI tính toán', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrefillNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: const [
          Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đã tự điền cân nặng, chiều cao, tuổi từ hồ sơ của bạn. Bạn chỉ cần chọn bài tập & thời gian (có thể sửa nếu cần).',
              style: TextStyle(fontSize: 12, color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormLayout({required bool isMobile}) {
    final fields = [
      _buildDropdown(),
      _buildTextField("Cân nặng (kg)", _weightController, Icons.scale),
      _buildTextField("Chiều cao (cm)", _heightController, Icons.height),
      _buildTextField("Tuổi", _ageController, Icons.person_outline),
      _buildTextField("Thời gian (phút)", _durationController, Icons.timer_outlined),
      _buildTextField("Nhịp tim (bpm)", _heartRateController, Icons.favorite_border),
    ];

    if (isMobile) {
      return Column(children: fields.expand((f) => [f, const SizedBox(height: 16)]).toList());
    } else {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 4,
        children: fields,
      );
    }
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedActivity,
      items: _activities.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
      onChanged: (val) => setState(() => _selectedActivity = val),
      decoration: const InputDecoration(labelText: "Loại bài tập", prefixIcon: Icon(Icons.fitness_center)),
      validator: (val) => val == null ? "Bắt buộc" : null,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: (val) => val == null || val.isEmpty ? "Bắt buộc" : null,
    );
  }

  Widget _buildPredictButton() {
    return _isLoading
        ? const CircularProgressIndicator()
        : ElevatedButton(
            onPressed: _predictCalories,
            child: const Text('TÍNH TOÁN KẾT QUẢ'),
          );
  }

  Widget _buildResultCard() {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
        border: Border.all(color: AppTheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          const Text('KẾT QUẢ DỰ ĐOÁN', style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          Text(
            '${_predictedCalories!.toStringAsFixed(1)} kcal',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          const Text('Lượng calo bạn sẽ tiêu hao trong buổi tập này', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildHistoryButton() {
    return OutlinedButton.icon(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
      icon: const Icon(Icons.history),
      label: const Text('XEM LỊCH SỬ DỰ ĐOÁN'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
