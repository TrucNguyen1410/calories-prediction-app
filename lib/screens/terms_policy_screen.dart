import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../widgets/animated_icon_button.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class TermsPolicyScreen extends StatelessWidget {
  const TermsPolicyScreen({super.key});

  static const _sections = [
    (
      'Mục đích sử dụng và Miễn trừ trách nhiệm y tế',
      'HealthAI cung cấp thông tin thống kê, theo dõi calo và phân tích thói quen luyện tập. Chúng tôi không cung cấp lời khuyên y tế chuyên nghiệp. Vui lòng tham khảo ý kiến bác sĩ trước khi thay đổi chế độ dinh dưỡng hoặc tập luyện.',
    ),
    (
      'Thu thập và Xử lý Dữ liệu',
      'Ứng dụng thu thập thông tin về chiều cao, cân nặng, giới tính và tuổi của bạn để cá nhân hóa chỉ số BMI và mức năng lượng tiêu hao. Dữ liệu tập luyện được nhập thủ công hoặc đồng bộ hóa trực tiếp qua Google Fit API.',
    ),
    (
      'Cam kết Bảo mật của bên thứ 3 (Google API Services)',
      'Thông tin truy cập Google Fit tuân thủ hoàn toàn Chính sách dữ liệu người dùng của Google API Services. Chúng tôi không chia sẻ dữ liệu sức khỏe của bạn cho bất kỳ bên thứ ba nào ngoại trừ việc xử lý cục bộ trên thiết bị và máy chủ bảo mật của ứng dụng.',
    ),
    (
      'Quyền kiểm soát của Người dùng',
      'Bạn có quyền ngắt kết nối Google Fit, sửa đổi hoặc xóa hoàn toàn thông tin cá nhân của mình bất kỳ lúc nào thông qua cài đặt ứng dụng.',
    ),
    (
      'Liên hệ & Đóng góp ý kiến',
      'Mọi phản hồi xin gửi về email hỗ trợ: support@healthai.vn hoặc qua mục Đóng góp ý kiến trong ứng dụng.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E1F22) : Colors.grey[100]!;
    final cardColor = isDark ? const Color(0xFF2B2D31) : Colors.white;
    final textColor = isDark ? const Color(0xFFF2F3F5) : Colors.black87;
    final subTextColor = isDark ? const Color(0xFF949BA4) : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: bgColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Điều khoản & Chính sách', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        // App bar "liquid glass": trong suốt + blur, lộ mờ nội dung cuộn phía
        // sau thay vì nền đục phẳng như trước.
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.7),
                border: Border(bottom: BorderSide(color: (isDark ? Colors.white : Colors.black).withOpacity(0.06))),
              ),
            ),
          ),
        ),
        leading: AnimatedIconButton(
          icon: LucideIcons.arrowLeft,
          color: textColor,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, kToolbarHeight + MediaQuery.of(context).padding.top + 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(LucideIcons.shieldCheck, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Điều khoản sử dụng & Chính sách bảo mật',
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: textColor, letterSpacing: -0.2),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cập nhật lần cuối: Tháng 5/2026',
                          style: TextStyle(fontSize: 12.5, color: subTextColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              for (int i = 0; i < _sections.length; i++)
                _buildSection(
                  index: i + 1,
                  title: _sections[i].$1,
                  content: _sections[i].$2,
                  cardColor: cardColor,
                  textColor: textColor,
                  isDark: isDark,
                ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Cảm ơn bạn đã tin dùng HealthAI!',
                  style: TextStyle(
                    fontSize: 13,
                    color: subTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required int index,
    required String title,
    required String content,
    required Color cardColor,
    required Color textColor,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.04), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24, height: 24,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(isDark ? 0.22 : 0.12), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('$index', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            textAlign: TextAlign.justify,
            style: TextStyle(
              fontSize: 13.5,
              color: textColor,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
