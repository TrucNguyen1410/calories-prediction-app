import 'health_connect_diagnostic.dart';

/// Phiên bản dùng cho Flutter Web — package `health` KHÔNG hỗ trợ Web (chỉ
/// Android/iOS), nên bản Web dùng stub này thay vì import trực tiếp `health`
/// (import thẳng sẽ làm `flutter build web` lỗi vì thiếu triển khai cho Web).
/// Việc chọn file này thay vì [health_connect_service_io.dart] được quyết định
/// tự động ở biên dịch qua conditional export trong `health_connect_service.dart`.
class HealthConnectService {
  Future<({int steps, double caloriesBurned})?> fetchToday() async => null;

  Future<HealthConnectDiagnostic> runDiagnostic() async {
    return const HealthConnectDiagnostic(
      platformSupported: false,
      permissionGranted: false,
      errorMessage: 'Health Connect/HealthKit chỉ hoạt động trên app cài thật (Android/iOS), không chạy được trên bản Web.',
    );
  }
}
