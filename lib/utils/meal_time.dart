// Tự động xác định & chuẩn hoá loại bữa ăn theo thời gian thực tế lúc ghi nhận,
// để đồng bộ giữa Thực đơn (AI) và Lịch sử ăn uống mà không cần người dùng tự chọn.

/// Xác định bữa ăn (Sáng/Trưa/Tối/Snack) dựa trên giờ hiện tại.
/// Dùng khi log món ăn qua ảnh/AI ở Trang chủ — luôn khớp với thời điểm ăn thật
/// thay vì gán cứng một loại chung chung.
String detectMealTypeByTime(DateTime time) {
    final minutesOfDay = time.hour * 60 + time.minute;
    const morningStart = 4 * 60; // 04:00
    const lunchStart = 10 * 60 + 30; // 10:30
    const snackStart = 14 * 60 + 30; // 14:30
    const dinnerStart = 17 * 60 + 30; // 17:30
    const nightEnd = 22 * 60; // 22:00

    if (minutesOfDay >= morningStart && minutesOfDay < lunchStart) return 'Sáng';
    if (minutesOfDay >= lunchStart && minutesOfDay < snackStart) return 'Trưa';
    if (minutesOfDay >= snackStart && minutesOfDay < dinnerStart) return 'Snack';
    if (minutesOfDay >= dinnerStart && minutesOfDay < nightEnd) return 'Tối';
    return 'Snack'; // đêm khuya / trước 4h sáng — tính là ăn vặt
}

/// Chuẩn hoá nhãn bữa ăn (vd "Bữa sáng", "Bữa phụ" từ Thực đơn AI) về đúng
/// 4 giá trị enum dùng trong Meal: Sáng/Trưa/Tối/Snack — để so khớp slot
/// giữa Thực đơn và Lịch sử ăn uống dù nhãn hiển thị khác nhau.
String normalizeMealTypeLabel(String? raw) {
    final s = (raw ?? '').toLowerCase();
    if (s.contains('sáng')) return 'Sáng';
    if (s.contains('trưa')) return 'Trưa';
    if (s.contains('tối')) return 'Tối';
    return 'Snack';
}
