import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';

/// Kết quả chẩn đoán chi tiết từng bước khi thử đọc Health Connect/HealthKit —
/// dùng cho màn hình "Kiểm tra Health Connect" (Hồ sơ) để người dùng tự test
/// xem thiết bị của họ có kết nối được không, thay vì chỉ nhận true/false.
class HealthConnectDiagnostic {
  final bool platformSupported; // false nếu đang chạy trên Web
  final bool permissionGranted; // đã cấp quyền Activity Recognition + Health Connect/HealthKit chưa
  final int? steps;
  final double? caloriesBurned;
  final String? errorMessage;

  const HealthConnectDiagnostic({
    required this.platformSupported,
    required this.permissionGranted,
    this.steps,
    this.caloriesBurned,
    this.errorMessage,
  });

  bool get success => platformSupported && permissionGranted && errorMessage == null;
}

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
  /// hoặc có lỗi khi đọc dữ liệu — để bên gọi (fallback tự động) tự quyết định
  /// bước tiếp theo mà không cần biết lý do cụ thể.
  Future<({int steps, double caloriesBurned})?> fetchToday() async {
    final diag = await runDiagnostic();
    if (!diag.success) return null;
    return (steps: diag.steps ?? 0, caloriesBurned: diag.caloriesBurned ?? 0);
  }

  /// Giống [fetchToday] nhưng trả về đầy đủ chi tiết từng bước — dùng để TEST
  /// thủ công (màn hình "Kiểm tra Health Connect" trong Hồ sơ), giúp biết chính
  /// xác đang vướng ở đâu (không hỗ trợ Web / chưa cài Health Connect / từ chối
  /// quyền / không có dữ liệu hôm nay...) thay vì chỉ nhận về null.
  Future<HealthConnectDiagnostic> runDiagnostic() async {
    if (kIsWeb) {
      return const HealthConnectDiagnostic(
        platformSupported: false,
        permissionGranted: false,
        errorMessage: 'Health Connect/HealthKit chỉ hoạt động trên app cài thật (Android/iOS), không chạy được trên bản Web.',
      );
    }

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
