import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

/// Đọc số bước chân & calo tiêu hao hôm nay từ Health Connect (Android) /
/// HealthKit (iOS) qua package `health`.
///
/// Đây là nguồn dữ liệu DỰ PHÒNG: chỉ được gọi khi đồng bộ Google Fit thất bại
/// (xem `HealthNotifier.refreshAll` trong `health_provider.dart`), để app vẫn
/// tiếp tục có số liệu vận động thật ngay cả khi Google Fit API ngừng hoạt động.
/// Không hoạt động trên Flutter Web (Health Connect/HealthKit là API cấp hệ
/// điều hành, chỉ có trên thiết bị thật).
class HealthConnectService {
  final Health _health = Health();

  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  /// Trả về null nếu không chạy trên thiết bị thật, người dùng từ chối quyền,
  /// hoặc có lỗi khi đọc dữ liệu — để bên gọi tự quyết định fallback tiếp theo.
  Future<({int steps, double caloriesBurned})?> fetchToday() async {
    if (kIsWeb) return null;

    try {
      await Permission.activityRecognition.request();

      final authorized = await _health.requestAuthorization(
        _types,
        permissions: _types.map((_) => HealthDataAccess.READ).toList(),
      );
      if (!authorized) return null;

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final steps = await _health.getTotalStepsInInterval(midnight, now) ?? 0;

      final calorieData = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: midnight,
        endTime: now,
      );
      double caloriesBurned = 0;
      for (final point in calorieData) {
        final value = point.value;
        if (value is NumericHealthValue) {
          caloriesBurned += value.numericValue.toDouble();
        }
      }

      return (steps: steps, caloriesBurned: caloriesBurned);
    } catch (e) {
      // Máy không cài Health Connect, người dùng từ chối quyền, hoặc lỗi khác —
      // coi như không có dữ liệu dự phòng, không chặn luồng chính của app.
      return null;
    }
  }
}
