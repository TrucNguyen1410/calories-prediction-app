// Bản thay thế cho build native (Android/iOS app) — không cần xin quyền JS,
// sensors_plus tự đọc được cảm biến trực tiếp trên các nền tảng này.
Future<bool> requestMotionPermission() async => true;
