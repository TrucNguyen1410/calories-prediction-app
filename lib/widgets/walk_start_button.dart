// Nút "Bắt đầu" cho tính năng đếm bước — trên web phải dùng nút HTML gốc
// (xem walk_start_button_web.dart) thay vì nút Flutter thường, vì Safari trên
// iPhone chỉ công nhận lệnh xin quyền cảm biến chuyển động khi nó được gọi
// NGAY trong 1 cú chạm DOM thật, còn nút Flutter thường đi qua nhiều lớp xử lý
// cử chỉ nội bộ nên tới lúc gọi được JS thì Safari đã coi hết hạn "tin cậy".
export 'walk_start_button_stub.dart' if (dart.library.html) 'walk_start_button_web.dart';
