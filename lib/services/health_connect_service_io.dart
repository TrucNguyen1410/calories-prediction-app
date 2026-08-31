import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'health_connect_diagnostic.dart';

/// Đọc số bước chân & calo tiêu hao hôm nay từ Health Connect (Android) /
/// HealthKit (iOS) qua package `health`. Chỉ được biên dịch cho Android/iOS/
/// desktop (bất kỳ target nào có dart:io) — bản Web dùng
/// [health_connect_service_stub.dart] thay thế, xem `health_connect_service.dart`.
///
/// Đây là nguồn dữ liệu DỰ PHÒNG: chỉ được gọi khi đồng bộ Google Fit thất bại
/// (xem `HealthNotifier.refreshAll` trong `health_provider.dart`), để app vẫn
/// tiếp tục có số liệu vận động thật ngay cả khi Google Fit API ngừng hoạt động.
class HealthConnectService {
  final Health _health = Health();

  static const _types = [
    HealthDataType.STEPS,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  /// Trả về null nếu người dùng từ chối quyền hoặc có lỗi khi đọc dữ liệu —
  /// để bên gọi (fallback tự động) tự quyết định bước tiếp theo mà không cần
  /// biết lý do cụ thể.
  Future<({int steps, double caloriesBurned})?> fetchToday() async {
    final diag = await runDiagnostic();
    if (!diag.success) return null;
    return (steps: diag.steps ?? 0, caloriesBurned: diag.caloriesBurned ?? 0);
  }

  /// Giống [fetchToday] nhưng trả về đầy đủ chi tiết từng bước — dùng để TEST
  /// thủ công (màn hình "Kiểm tra Health Connect" trong Hồ sơ), giúp biết chính
  /// xác đang vướng ở đâu (chưa cài Health Connect / từ chối quyền / không có
  /// dữ liệu hôm nay...) thay vì chỉ nhận về null.
  Future<HealthConnectDiagnostic> runDiagnostic() async {
    try {
      await Permission.activityRecognition.request();

      final authorized = await _health.requestAuthorization(
        _types,
        permissions: _types.map((_) => HealthDataAccess.READ).toList(),
      );
      if (!authorized) {
        return const HealthConnectDiagnostic(
          platformSupported: true,
          permissionGranted: false,
          errorMessage: 'Chưa cấp quyền truy cập Health Connect/HealthKit (hoặc chưa cài app Health Connect trên máy).',
        );
      }

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

      return HealthConnectDiagnostic(
        platformSupported: true,
        permissionGranted: true,
        steps: steps,
        caloriesBurned: caloriesBurned,
      );
    } catch (e) {
      return HealthConnectDiagnostic(
        platformSupported: true,
        permissionGranted: false,
        errorMessage: 'Lỗi khi đọc dữ liệu: $e',
      );
    }
  }
}
