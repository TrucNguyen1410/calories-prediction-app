import 'package:flutter_test/flutter_test.dart';
import 'package:do_an_chuyen_nganh/models/workout.dart';

void main() {
  group('Workout.fromJson', () {
    test('phân tích đầy đủ các trường từ JSON MongoDB', () {
      final json = {
        '_id': 'abc123',
        'activityType': 'Chạy bộ',
        'weight': 65,
        'height': 170,
        'age': 25,
        'duration': 45,
        'heartRate': 130,
        'calories': 350.5,
        'date': '2026-07-03T10:00:00.000Z',
      };

      final w = Workout.fromJson(json);

      expect(w.id, 'abc123');
      expect(w.activityType, 'Chạy bộ');
      expect(w.weight, 65.0);
      expect(w.height, 170.0);
      expect(w.age, 25);
      expect(w.duration, 45);
      expect(w.heartRate, 130);
      expect(w.calories, 350.5);
      expect(w.date, '2026-07-03T10:00:00.000Z');
    });

    test('dùng giá trị mặc định an toàn khi thiếu trường', () {
      final w = Workout.fromJson({});
      expect(w.activityType, 'Không xác định');
      expect(w.weight, 0.0);
      expect(w.calories, 0.0);
      expect(w.date, '');
    });

    test('chấp nhận cả heart_rate (snake_case) từ backend', () {
      final w = Workout.fromJson({'heart_rate': 145});
      expect(w.heartRate, 145);
    });
  });

  group('Workout.toJson', () {
    test('vòng chuyển đổi giữ nguyên dữ liệu', () {
      final w = Workout(
        activityType: 'Gym',
        weight: 70,
        height: 175,
        age: 30,
        duration: 60,
        heartRate: 140,
        calories: 500,
        date: '2026-07-03',
      );
      final json = w.toJson();
      final w2 = Workout.fromJson(json);
      expect(w2.activityType, w.activityType);
      expect(w2.weight, w.weight);
      expect(w2.calories, w.calories);
    });
  });
}
