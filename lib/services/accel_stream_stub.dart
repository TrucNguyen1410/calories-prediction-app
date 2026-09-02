// Bản cho native app (Android/iOS) — sensors_plus đọc trực tiếp cảm biến hệ
// điều hành, không gặp vấn đề của trình duyệt nên dùng thẳng như bình thường.
import 'package:sensors_plus/sensors_plus.dart';

class AccelSample {
  const AccelSample(this.x, this.y, this.z);
  final double x, y, z;
}

Stream<AccelSample> accelerometerSampleStream() {
  return accelerometerEventStream().map((e) => AccelSample(e.x, e.y, e.z));
}
