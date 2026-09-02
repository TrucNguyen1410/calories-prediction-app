// Gọi hàm JS `requestMotionPermission` khai báo trong web/index.html — bắt buộc
// trên iOS Safari 13+ (DeviceMotionEvent.requestPermission), các trình duyệt khác
// hàm JS đó tự trả về true ngay.
import 'dart:js_interop';

@JS('requestMotionPermission')
external JSPromise<JSBoolean> _requestMotionPermission();

Future<bool> requestMotionPermission() async {
  try {
    final granted = await _requestMotionPermission().toDart;
    return granted.toDart;
  } catch (_) {
    return true;
  }
}
