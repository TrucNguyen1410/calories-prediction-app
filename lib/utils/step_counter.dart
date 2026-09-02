import 'dart:math' as math;

/// Bộ đếm bước chân đơn giản theo kiểu "peak detection" trên độ lớn vector
/// gia tốc (accelerometer magnitude). Không chính xác bằng pedometer phần cứng
/// chuyên dụng, nhưng đủ dùng để demo tính năng đếm bước qua cảm biến trình duyệt.
class StepCounter {
  StepCounter({
    this.threshold = 1.2,
    this.minStepInterval = const Duration(milliseconds: 300),
  });

  /// Biên độ dao động tối thiểu (m/s²) so với trọng lực để tính là 1 bước.
  final double threshold;

  /// Khoảng cách tối thiểu giữa 2 bước liên tiếp — chống đếm trùng do rung nhiễu.
  final Duration minStepInterval;

  int _steps = 0;
  double _lastMagnitude = 9.8; // xấp xỉ trọng lực lúc đứng yên
  bool _rising = false;
  DateTime? _lastStepTime;

  int get steps => _steps;

  void addSample(double x, double y, double z) {
    final magnitude = math.sqrt(x * x + y * y + z * z);
    final delta = magnitude - _lastMagnitude;

    if (delta > threshold && !_rising) {
      _rising = true;
      final now = DateTime.now();
      if (_lastStepTime == null || now.difference(_lastStepTime!) > minStepInterval) {
        _steps++;
        _lastStepTime = now;
      }
    } else if (delta < -threshold * 0.5) {
      _rising = false;
    }

    _lastMagnitude = magnitude;
  }

  void reset() {
    _steps = 0;
    _lastMagnitude = 9.8;
    _rising = false;
    _lastStepTime = null;
  }
}
