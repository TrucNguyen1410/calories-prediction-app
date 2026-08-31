// Điểm import công khai duy nhất — KHÔNG import trực tiếp health_connect_service_io.dart
// hay _stub.dart từ nơi khác, luôn import file này.
//
// Package `health` chỉ hỗ trợ Android/iOS, không hỗ trợ Web. Nếu import thẳng
// nó vào code dùng chung cho cả Web, lệnh `flutter build web` (Vercel dùng để
// build bản web) sẽ lỗi. Conditional export dưới đây tự chọn đúng bản theo nền
// tảng đang biên dịch: bản Web luôn dùng stub (dart:io không tồn tại trên Web),
// Android/iOS/desktop dùng bản thật gọi package `health`.
export 'health_connect_diagnostic.dart';
export 'health_connect_service_stub.dart'
    if (dart.library.io) 'health_connect_service_io.dart';
