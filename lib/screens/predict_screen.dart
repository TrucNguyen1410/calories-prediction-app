import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../services/api_service.dart';
import 'history_screen.dart';

class PredictScreen extends StatefulWidget {
  const PredictScreen({Key? key}) : super(key: key);

  @override
  State<PredictScreen> createState() => _PredictScreenState();
}

class _PredictScreenState extends State<PredictScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  // Controllers
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _heartRateController = TextEditingController();

  // Loại bài tập (Dropdown)
  final List<String> _activities = [
    "Gym",
    "Chạy bộ",
    "Đạp xe",
    "Bơi lội",
    "Yoga",
    "Leo núi",
    "Đi bộ nhanh"
  ];
  String? _selectedActivity;

  double? _predictedCalories;
  bool _isLoading = false;

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

    // Gọi API
    final result = await _apiService.predictCalories(workout);

    setState(() {
      _isLoading = false;
      _predictedCalories = result;
    });

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔥 Dự đoán: ${result.toStringAsFixed(1)} kcal'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Dự đoán thất bại. Vui lòng thử lại!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dự đoán Calo tiêu hao"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // --- Header Card ---
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.blue.shade100],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calculate, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dự đoán Calo',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nhập thông tin để dự đoán lượng calo tiêu hao',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // --- Form Fields ---
              // Dropdown loại bài tập
              DropdownButtonFormField<String>(
                value: _selectedActivity,
                items: _activities
                    .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedActivity = value),
                decoration: InputDecoration(
                  labelText: "Loại bài tập",
                  labelStyle: const TextStyle(color: Colors.blue),
                  hintText: "Chọn loại bài tập",
                  prefixIcon: Icon(Icons.fitness_center, color: Colors.blue.withOpacity(0.6)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
                validator: (value) => value == null ? "Hãy chọn loại bài tập" : null,
              ),
              const SizedBox(height: 16),

              // --- Form Fields (stacked, full-width, equal height) ---
              Column(
                children: [
                  SizedBox(
                    height: 64,
                    child: _buildCompactTextField("Cân nặng (kg)", _weightController, Icons.scale, true),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 64,
                    child: _buildCompactTextField("Chiều cao (cm)", _heightController, Icons.height, true),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 64,
                    child: _buildCompactTextField("Tuổi", _ageController, Icons.person, true),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 64,
                    child: _buildCompactTextField("Thời gian (phút)", _durationController, Icons.schedule, true),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 64,
                    child: _buildCompactTextField("Nhịp tim trung bình (bpm)", _heartRateController, Icons.favorite, true),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- Predict Button ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_graph, size: 22),
                  label: Text(
                    _isLoading ? "Đang tính toán..." : "🔥 Dự đoán Calo",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  onPressed: _isLoading ? null : _predictCalories,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- Result Card ---
              if (_predictedCalories != null)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 12, offset: Offset(0, 4)),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.local_fire_department, color: Colors.red.shade400, size: 32),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Kết quả dự đoán",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "${_predictedCalories!.toStringAsFixed(1)} kcal",
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Lượng calo bạn sẽ tiêu hao",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildResultStat('Calo/Phút', '${(_predictedCalories! / (int.tryParse(_durationController.text) ?? 1)).toStringAsFixed(1)}'),
                            Container(width: 1, height: 30, color: Colors.blue.withOpacity(0.2)),
                            _buildResultStat('Calo/Kg', '${(_predictedCalories! / (double.tryParse(_weightController.text) ?? 1)).toStringAsFixed(1)}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // --- View History Button ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, color: Colors.blue.shade400, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Xem lịch sử tập luyện",
                            style: TextStyle(color: Colors.blue.shade400, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isNumber,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blue, fontSize: 11),
        hintText: label,
        hintStyle: TextStyle(fontSize: 11, color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: Colors.blue.withOpacity(0.6), size: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.withOpacity(0.3), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      style: const TextStyle(fontSize: 12),
      validator: (value) {
        if (value == null || value.isEmpty) return "Bắt buộc";
        return null;
      },
    );
  }

  Widget _buildResultStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ],
    );
  }
}
