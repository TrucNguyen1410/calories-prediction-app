import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';
import '../providers/tour_provider.dart';
import 'main_screen.dart';

class UserGuideScreen extends ConsumerWidget {
  const UserGuideScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Nền tối đồng bộ với Theme Discord của ứng dụng
    final backgroundColor = isDark ? const Color(0xFF1E1F22) : Colors.grey[100];
    final cardColor = isDark ? const Color(0xFF2B2D31) : Colors.white;
    final textColor = isDark ? const Color(0xFFF2F3F5) : Colors.black87;
    final subtitleColor = isDark ? const Color(0xFF949BA4) : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Hướng dẫn sử dụng'),
        backgroundColor: isDark ? const Color(0xFF2B2D31) : AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Nút Khám phá nhanh (Interactive Tour) ở trên cùng
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF8A2BE2), Color(0xFF4B0082)], // Tím Gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8A2BE2).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  // Kích hoạt trạng thái chạy tour ở trang chủ
                  ref.read(tourStartProvider.notifier).state = true;
                  // Chuyển tab về Trang chủ (index 0)
                  ref.read(mainTabProvider.notifier).state = 0;
                  // Quay lại màn hình chính
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.explore_outlined, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      '🚀 Khám phá nhanh (Interactive Tour)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Phần Hướng dẫn bằng Text chia mục rõ ràng
            _buildGuideCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              icon: Icons.smart_toy_outlined,
              iconColor: Colors.purpleAccent,
              title: '1. Trợ lý Sức khỏe AI',
              description: 'Trò chuyện, phân tích & ghi chép bằng AI',
              steps: [
                'Trò chuyện trực tiếp: Nhấn bong bóng Robot tròn ở góc màn hình để hỏi đáp về sức khỏe, dinh dưỡng, tập luyện.',
                'Ghi buổi tập bằng lời: Gõ "Tôi vừa chạy bộ 30 phút", AI tự tính calo đã đốt và cho nút "Lưu" vào nhật ký.',
                'Lưu nhật ký: Bấm "Lưu" trên bong bóng của AI để đồng bộ calo vào biểu đồ thống kê.',
              ],
            ),
            const SizedBox(height: 16),

            _buildGuideCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              icon: Icons.restaurant_menu_outlined,
              iconColor: Colors.greenAccent,
              title: '2. Dinh dưỡng: Phân tích & Thực đơn AI',
              description: 'Đếm calo món ăn và lập thực đơn 7 ngày',
              steps: [
                'Phân tích món ăn: Ở thẻ "Nhật ký dinh dưỡng AI", nhập tên món hoặc tải ẢNH món ăn lên, AI sẽ ước tính calo và các chất (đạm, tinh bột, béo).',
                'Tạo thực đơn 7 ngày: Vào tab Thực đơn, bấm "Tạo thực đơn AI" và mô tả nhu cầu (ví dụ: "Ăn chay giảm cân 1800kcal").',
                'Chỉnh sửa món: Nhấn biểu tượng cây bút ở mỗi món để thay thế; AI cảnh báo nếu vượt calo mục tiêu.',
              ],
            ),
            const SizedBox(height: 16),

            _buildGuideCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              icon: Icons.local_fire_department_outlined,
              iconColor: Colors.orangeAccent,
              title: '3. Mục tiêu Calo cá nhân (TDEE) & BMI',
              description: 'Mục tiêu calo tính riêng cho bạn',
              steps: [
                'Đặt mục tiêu: Vào Cá nhân → "Mục tiêu & Mức vận động" chọn Giảm/Giữ/Tăng cân và mức vận động.',
                'Mục tiêu calo tự động: Hệ thống tính lượng calo nạp mỗi ngày (TDEE) dựa trên cân nặng, chiều cao, tuổi, giới tính và mục tiêu — thay cho con số cố định.',
                'BMI chuẩn Châu Á: Chỉ số BMI phân loại theo mốc Việt Nam (Thiếu cân → Béo phì độ II), hiển thị trực quan trên thẻ ở Trang chủ.',
              ],
            ),
            const SizedBox(height: 16),

            _buildGuideCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              icon: Icons.monitor_weight_outlined,
              iconColor: Colors.blueAccent,
              title: '4. Hồ sơ Sức khỏe & Dự đoán ML',
              description: 'Theo dõi cân nặng và dự đoán calo tiêu hao',
              steps: [
                'Ghi cân nặng: Vào Cá nhân → "Hồ sơ sức khỏe", bấm "Cập nhật cân nặng" để lưu số đo; app vẽ biểu đồ xu hướng cân nặng & BMI thật theo thời gian.',
                'Dự đoán calo (AI/ML): Vào "Dự đoán calo tiêu hao", chọn bài tập và nhập thời gian — mô hình Học máy sẽ ước tính lượng calo đốt (các chỉ số cơ thể tự điền từ hồ sơ).',
              ],
            ),
            const SizedBox(height: 16),

            _buildGuideCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              icon: Icons.directions_walk_outlined,
              iconColor: Colors.teal,
              title: '5. Nước uống & Bước chân (Google Fit)',
              description: 'Theo dõi vận động và nước uống hằng ngày',
              steps: [
                'Uống nước: Trên Trang chủ, dùng thẻ "Nước uống" với nút nhanh +250ml / +500ml; mục tiêu nước tính theo cân nặng.',
                'Đồng bộ Google Fit: Đăng nhập bằng Google (có Google Fit) — app tự động lấy SỐ BƯỚC hằng ngày và hiển thị trên thẻ "Bước chân hôm nay".',
                'Đồng bộ lại: Nếu phiên Google hết hạn, bấm "ĐĂNG NHẬP LẠI" trên thông báo để kết nối lại.',
              ],
            ),
            const SizedBox(height: 16),

            _buildGuideCard(
              context: context,
              cardColor: cardColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
              icon: Icons.manage_accounts_outlined,
              iconColor: Colors.pinkAccent,
              title: '6. Tài khoản & Cài đặt',
              description: 'Quản lý hồ sơ và bảo mật',
              steps: [
                'Sửa hồ sơ: Nhấn thẻ tên ở đầu trang Cá nhân để sửa Tên, Giới tính, Chiều cao, Cân nặng, Tuổi cùng lúc.',
                'Bảo mật: Đổi mật khẩu trong mục "Tài khoản & Bảo mật"; nếu quên mật khẩu, dùng "Quên mật khẩu?" ở màn đăng nhập để nhận mã OTP qua email.',
                'Giao diện & Dữ liệu: Bật/tắt Chế độ tối; có thể xóa tài khoản vĩnh viễn trong "Vùng nguy hiểm".',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required BuildContext context,
    required Color cardColor,
    required Color textColor,
    required Color subtitleColor,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required List<String> steps,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Column(
            children: steps.map((step) {
              // Tách theo dấu ':' ĐẦU TIÊN để không cắt mất phần mô tả có nhiều dấu ':'
              final idx = step.indexOf(': ');
              final titleText = idx >= 0 ? step.substring(0, idx + 2) : '';
              final detailText = idx >= 0 ? step.substring(idx + 2) : step;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 13,
                            color: textColor,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: titleText,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: detailText),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
