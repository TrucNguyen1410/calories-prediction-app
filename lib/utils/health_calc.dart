/// Các hàm tính toán sức khỏe phía client — đồng bộ logic với backend (utils/health.js).
/// Dùng để tính mục tiêu calo cá nhân hóa (TDEE) thay cho giá trị cố định 2000.
class HealthCalc {
  static const Map<String, double> activityFactors = {
    'sedentary': 1.2,
    'light': 1.375,
    'moderate': 1.55,
    'active': 1.725,
    'very_active': 1.9,
  };

  static const Map<String, String> activityLabels = {
    'sedentary': 'Ít vận động (ngồi nhiều)',
    'light': 'Vận động nhẹ (1-3 buổi/tuần)',
    'moderate': 'Vận động vừa (3-5 buổi/tuần)',
    'active': 'Vận động nhiều (6-7 buổi/tuần)',
    'very_active': 'Rất nhiều / lao động nặng',
  };

  static const Map<String, String> goalLabels = {
    'lose': 'Giảm cân',
    'maintain': 'Giữ cân',
    'gain': 'Tăng cân',
  };

  /// Tính tuổi từ chuỗi ngày sinh (ISO). Trả về 25 nếu không xác định được.
  static int ageFromDob(dynamic dob) {
    if (dob == null) return 25;
    final dt = DateTime.tryParse(dob.toString());
    if (dt == null) return 25;
    final now = DateTime.now();
    int age = now.year - dt.year;
    if (now.month < dt.month || (now.month == dt.month && now.day < dt.day)) age--;
    return age.clamp(5, 120);
  }

  /// BMR theo công thức Mifflin-St Jeor.
  static double? bmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) return null;
    final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
    return gender == 'Nam' ? base + 5 : base - 161;
  }

  /// Mục tiêu calo nạp hằng ngày cá nhân hóa (đã điều chỉnh theo mục tiêu).
  /// Trả về null nếu thiếu dữ liệu để tính.
  static double? dailyCalorieTarget({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
    String goal = 'maintain',
    String activityLevel = 'light',
  }) {
    final b = bmr(weightKg: weightKg, heightCm: heightCm, age: age, gender: gender);
    if (b == null) return null;
    final factor = activityFactors[activityLevel] ?? 1.375;
    double tdee = b * factor;
    if (goal == 'lose') {
      tdee -= 500;
    } else if (goal == 'gain') {
      tdee += 500;
    }
    return tdee < 1200 ? 1200 : tdee.roundToDouble();
  }

  /// Mục tiêu nước uống hằng ngày (ml) ~ 35ml/kg, tối thiểu 1500ml.
  static double dailyWaterTargetMl(double weightKg) {
    if (weightKg <= 0) return 2000;
    final target = weightKg * 35;
    return target < 1500 ? 1500 : target;
  }
}
