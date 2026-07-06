import 'package:flutter_test/flutter_test.dart';
import 'package:do_an_chuyen_nganh/utils/health_calc.dart';

void main() {
  group('HealthCalc.dailyCalorieTarget', () {
    test('tính TDEE và điều chỉnh theo mục tiêu (Nam)', () {
      // BMR = 10*70 + 6.25*175 - 5*25 + 5 = 1673.75; *1.375 = 2301.4 -> 2301
      final maintain = HealthCalc.dailyCalorieTarget(
        weightKg: 70, heightCm: 175, age: 25, gender: 'Nam', goal: 'maintain', activityLevel: 'light',
      );
      expect(maintain, 2301);

      final lose = HealthCalc.dailyCalorieTarget(
        weightKg: 70, heightCm: 175, age: 25, gender: 'Nam', goal: 'lose', activityLevel: 'light',
      );
      expect(lose, 2301 - 500);

      final gain = HealthCalc.dailyCalorieTarget(
        weightKg: 70, heightCm: 175, age: 25, gender: 'Nam', goal: 'gain', activityLevel: 'light',
      );
      expect(gain, 2301 + 500);
    });

    test('không xuống dưới 1200 và trả null khi thiếu dữ liệu', () {
      final tiny = HealthCalc.dailyCalorieTarget(
        weightKg: 35, heightCm: 120, age: 80, gender: 'Nữ', goal: 'lose', activityLevel: 'sedentary',
      );
      expect(tiny! >= 1200, true);

      final missing = HealthCalc.dailyCalorieTarget(
        weightKg: 0, heightCm: 175, age: 25, gender: 'Nam',
      );
      expect(missing, null);
    });
  });

  group('HealthCalc khác', () {
    test('dailyWaterTargetMl ~35ml/kg, tối thiểu 1500', () {
      expect(HealthCalc.dailyWaterTargetMl(70), 2450);
      expect(HealthCalc.dailyWaterTargetMl(30), 1500); // 1050 -> clamp 1500
      expect(HealthCalc.dailyWaterTargetMl(0), 2000); // mặc định
    });

    test('ageFromDob trả tuổi hợp lệ, fallback 25', () {
      expect(HealthCalc.ageFromDob(null), 25);
      expect(HealthCalc.ageFromDob('không-hợp-lệ'), 25);
      final age = HealthCalc.ageFromDob('2000-01-01T00:00:00.000Z');
      expect(age >= 24 && age <= 27, true);
    });
  });
}
