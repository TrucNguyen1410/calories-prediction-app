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
              description: 'Trò chuyện và điều khiển bằng AI',
              steps: [
                'Trò chuyện trực tiếp: Nhấn vào bong bóng Robot tròn ở góc màn hình để mở khung chat hỏi đáp sức khỏe.',
                'Ghi chép nhanh: Gõ tin nhắn như "Tôi vừa ăn 1 bát phở bò" hoặc "Tôi vừa chạy bộ 30 phút" để AI phân tích calo.',
                'Lưu nhật ký: Bấm nút "Lưu" trực tiếp trên bong bóng chat của AI để đồng bộ calo đã tiêu hao hoặc nạp vào biểu đồ thống kê.',
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
              title: '2. Thực đơn Dinh dưỡng AI',
              description: 'Tạo và tùy chỉnh thực đơn ăn kiêng',
              steps: [
                'Tạo thực đơn 7 ngày: Nhấn nút "Tạo thực đơn AI" ở tab Thực đơn, nhập mô tả (ví dụ: "Ăn chay giảm cân 1800kcal") để nhận kế hoạch chi tiết từ AI.',
                'Chỉnh sửa món ăn: Nhấp vào biểu tượng chỉnh sửa (icon cây bút) nhỏ ở góc mỗi món ăn để thay thế hoặc điều chỉnh món ăn theo ý thích.',
                'Kiểm tra & Cảnh báo: Bấm "Kiểm tra AI" để AI thẩm định món ăn mới và đưa ra cảnh báo bảo mật, dinh dưỡng hoặc cảnh báo nếu bạn thêm món ăn đêm khuya.',
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
              title: '3. Nhật ký AI & Chỉ số BMI',
              description: 'Nhập liệu nhanh và quản lý thể trạng',
              steps: [
                'Gợi ý nhanh (Quick-tags): Sử dụng các thẻ gợi ý nhanh ở thẻ "Nhật ký dinh dưỡng AI" như "🥣 Ăn sáng", "🥗 Ăn trưa"... để điền nhanh nội dung món ăn.',
                'Chỉ số BMI chuẩn Châu Á: Thể hiện thể trạng thực tế của bạn với 5 phân loại từ Gầy đến Béo phì độ 2 theo mốc Việt Nam.',
                'Thước đo BMI (Gauge): Theo dõi vị trí cân nặng trực quan bằng dải màu gradient trên thanh thước đo ở góc phải thẻ BMI.',
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
              final parts = step.split(': ');
              final titleText = parts[0] + ': ';
              final detailText = parts.length > 1 ? parts[1] : '';
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
