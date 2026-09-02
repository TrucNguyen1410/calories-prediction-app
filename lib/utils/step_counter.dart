import 'dart:math' as math;

/// Bộ đếm bước chân đơn giản theo kiểu "peak detection" trên độ lớn vector
/// gia tốc (accelerometer magnitude), với mốc nền (baseline) tự thích nghi
/// bằng trung bình trượt (EMA) thay vì giả định cố định 9.8 (trọng lực) —
/// vì trên web, tuỳ trình duyệt/thiết bị mà dữ liệu thô có thể đã trừ sẵn
/// trọng lực hoặc chưa. Không chính xác bằng pedometer phần cứng chuyên
/// dụng, nhưng đủ dùng để demo tính năng đếm bước qua cảm biến trình duyệt.
class StepCounter {
  StepCounter({
    this.threshold = 1.5,
    this.minStepInterval = const Duration(milliseconds: 300),
    this.emaAlpha = 0.1,
  });

  /// Biên độ dao động tối thiểu (m/s²) so với mốc nền để tính là 1 bước.
  final double threshold;

  /// Khoảng cách tối thiểu giữa 2 bước liên tiếp — chống đếm trùng do rung nhiễu.
  final Duration minStepInterval;

  /// Hệ số làm mượt mốc nền (EMA) — nhỏ = nền trôi chậm, ổn định hơn.
  final double emaAlpha;

  int _steps = 0;
  double? _baseline;
  double? _lastMagnitude;
  bool _above = false;
  DateTime? _lastStepTime;
  int _sampleCount = 0;

  int get steps => _steps;
  int get sampleCount => _sampleCount;
  double? get lastMagnitude => _lastMagnitude;

  void addSample(double x, double y, double z) {
    final magnitude = math.sqrt(x * x + y * y + z * z);
    _sampleCount++;
    _lastMagnitude = magnitude;

    if (_baseline == null) {
      _baseline = magnitude;
      return;
    }

    final delta = magnitude - _baseline!;

    if (delta > threshold && !_above) {
      _above = true;
      final now = DateTime.now();
      if (_lastStepTime == null || now.difference(_lastStepTime!) > minStepInterval) {
        _steps++;
        _lastStepTime = now;
      }
    } else if (delta < threshold * 0.3) {
      _above = false;
    }

    // Nền trôi chậm theo thời gian để thích nghi khi đổi tư thế cầm máy,
    // không phụ thuộc việc dữ liệu thô có gồm trọng lực hay không.
    _baseline = _baseline! * (1 - emaAlpha) + magnitude * emaAlpha;
  }

  void reset() {
    _steps = 0;
    _baseline = null;
    _lastMagnitude = null;
    _above = false;
    _lastStepTime = null;
    _sampleCount = 0;
  }
}
