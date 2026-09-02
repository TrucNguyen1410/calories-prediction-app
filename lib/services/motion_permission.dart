// Xin quyền đọc cảm biến chuyển động (gia tốc kế) để đếm bước chân qua trình duyệt.
// Chỉ thật sự cần thiết trên iOS Safari (13+) — các nền tảng khác mặc định cho phép.
export 'motion_permission_stub.dart' if (dart.library.html) 'motion_permission_web.dart';
