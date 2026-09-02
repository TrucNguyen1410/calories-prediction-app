// Đọc thẳng sự kiện `devicemotion` gốc của trình duyệt bằng dart:html, bỏ qua
// package:sensors_plus cho nền tảng web — xem giải thích trong accel_stream.dart.
import 'dart:async';
import 'dart:html' as html;

class AccelSample {
  const AccelSample(this.x, this.y, this.z);
  final double x, y, z;
}

Stream<AccelSample> accelerometerSampleStream() {
  final controller = StreamController<AccelSample>.broadcast();
  StreamSubscription<html.DeviceMotionEvent>? sub;

  controller.onListen = () {
    sub = html.window.onDeviceMotion.listen((event) {
      // Trên nhiều bản iOS Safari, "acceleration" (đã trừ trọng lực) trả về
      // null — ưu tiên "accelerationIncludingGravity" vì luôn có giá trị thật.
      final acc = event.accelerationIncludingGravity ?? event.acceleration;
      if (acc == null) return;

      final x = (acc.x ?? 0).toDouble();
      final y = (acc.y ?? 0).toDouble();
      final z = (acc.z ?? 0).toDouble();
      if (x == 0 && y == 0 && z == 0) return; // mẫu rỗng/không hợp lệ, bỏ qua

      controller.add(AccelSample(x, y, z));
    });
  };
  controller.onCancel = () {
    sub?.cancel();
    sub = null;
  };

  return controller.stream;
}
