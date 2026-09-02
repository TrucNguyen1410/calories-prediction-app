// Nguồn dữ liệu gia tốc kế dùng chung cho tính năng đếm bước — trên web KHÔNG
// dùng package:sensors_plus (đã xác nhận qua test thật: popup xin quyền hiện
// đúng, người dùng bấm "Cho phép", nhưng sensors_plus vẫn không đọc được dữ
// liệu liên tục trên Safari iPhone — khớp với issue đã biết của package này
// trên web). Thay vào đó đọc thẳng sự kiện `devicemotion` của trình duyệt.
export 'accel_stream_stub.dart' if (dart.library.html) 'accel_stream_web.dart';
