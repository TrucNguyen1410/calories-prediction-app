import 'package:flutter/material.dart';
import '../theme.dart';

class TermsPolicyScreen extends StatelessWidget {
  const TermsPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF2B2D31) : Colors.white;
    final textColor = isDark ? const Color(0xFFF2F3F5) : Colors.black87;
    final subTextColor = isDark ? const Color(0xFF949BA4) : Colors.grey[600];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Điều khoản & Chính sách', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ĐIỀU KHOẢN SỬ DỤNG & CHÍNH SÁCH BẢO MẬT (HEALTHAI)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cập nhật lần cuối: Tháng 5/2026',
                style: TextStyle(
                  fontSize: 13,
                  color: subTextColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Divider(height: 32),
              
              _buildSection(
                title: '1. Mục đích sử dụng và Miễn trừ trách nhiệm y tế',
                content: 'HealthAI cung cấp thông tin thống kê, theo dõi calo và phân tích thói quen luyện tập. Chúng tôi không cung cấp lời khuyên y tế chuyên nghiệp. Vui lòng tham khảo ý kiến bác sĩ trước khi thay đổi chế độ dinh dưỡng hoặc tập luyện.',
                textColor: textColor,
              ),
              _buildSection(
                title: '2. Thu thập và Xử lý Dữ liệu',
                content: 'Ứng dụng thu thập thông tin về chiều cao, cân nặng, giới tính và tuổi của bạn để cá nhân hóa chỉ số BMI và mức năng lượng tiêu hao. Dữ liệu tập luyện được nhập thủ công hoặc đồng bộ hóa trực tiếp qua Google Fit API.',
                textColor: textColor,
              ),
              _buildSection(
                title: '3. Cam kết Bảo mật của bên thứ 3 (Google API Services)',
                content: 'Thông tin truy cập Google Fit tuân thủ hoàn toàn Chính sách dữ liệu người dùng của Google API Services. Chúng tôi không chia sẻ dữ liệu sức khỏe của bạn cho bất kỳ bên thứ ba nào ngoại trừ việc xử lý cục bộ trên thiết bị và máy chủ bảo mật của ứng dụng.',
                textColor: textColor,
              ),
              _buildSection(
                title: '4. Quyền kiểm soát của Người dùng',
                content: 'Bạn có quyền ngắt kết nối Google Fit, sửa đổi hoặc xóa hoàn toàn thông tin cá nhân của mình bất kỳ lúc nào thông qua cài đặt ứng dụng.',
                textColor: textColor,
              ),
              _buildSection(
                title: '5. Liên hệ & Đóng góp ý kiến',
                content: 'Mọi phản hồi xin gửi về email hỗ trợ: support@healthai.vn hoặc qua mục Đóng góp ý kiến trong ứng dụng.',
                textColor: textColor,
              ),
              const SizedBox(height: 24),
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
    required String title,
    required String content,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.primary, // Styled in primary blue color
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            textAlign: TextAlign.justify, // Justified text
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
