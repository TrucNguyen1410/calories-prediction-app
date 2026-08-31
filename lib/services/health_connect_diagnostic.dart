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
