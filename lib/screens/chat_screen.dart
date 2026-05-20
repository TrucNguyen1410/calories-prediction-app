import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';
import '../services/api_service.dart';
import '../providers/health_provider.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Tự động cuộn xuống cuối khi có tin nhắn mới
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Gọi scroll khi có tin nhắn mới hoặc đang load
    if (chatState.messages.isNotEmpty || chatState.isLoading) {
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Lịch sử trò chuyện',
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: const Text('Trợ lý Sức khỏe AI (Gemini)'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            tooltip: 'Cuộc trò chuyện mới',
            onPressed: () {
              ref.read(chatProvider.notifier).startNewChat();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Xóa lịch sử chat hiện tại',
            onPressed: () => ref.read(chatProvider.notifier).clearChat(),
          )
        ],
      ),
      drawer: Drawer(
        child: _buildChatHistorySidebar(chatState),
      ),
      body: Center(
        child: Container(
          // Giới hạn chiều rộng trên Web để giao diện không bị quá trải dài
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey[50],
            border: Border.symmetric(
              vertical: BorderSide(color: isDark ? const Color(0xFF35373C) : Colors.grey[200]!, width: 1),
            ),
          ),
          child: Column(
            children: [
              // 1. Danh sách tin nhắn
              Expanded(
                child: chatState.messages.isEmpty && !chatState.isLoading
                    ? _buildWelcomeScreen()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatState.messages.length) {
                            return _buildTypingIndicator();
                          }
                          final message = chatState.messages[index];
                          return _buildChatBubble(message);
                        },
                      ),
              ),

              // Hiển thị lỗi nếu có
              if (chatState.error != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    chatState.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),

              // 2. Ô nhập liệu
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  // Giao diện chào mừng khi chưa có tin nhắn
  Widget _buildWelcomeScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chào mừng bạn đến với Trợ lý Sức khỏe AI!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFF2F3F5) : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy hỏi tôi bất kỳ câu hỏi nào về sức khỏe, dinh dưỡng hoặc gõ bài tập luyện của bạn (Ví dụ: "Tôi chạy bộ 30 phút") để lưu vào nhật ký nhé.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? const Color(0xFFB5BAC1) : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sidebar danh sách lịch sử hội thoại (Drawer)
  Widget _buildChatHistorySidebar(ChatState chatState) {
    return Container(
      color: const Color(0xFF1E1E2E), // Giao diện tối sang trọng
      child: SafeArea(
        child: Column(
          children: [
            // Nút Thêm cuộc trò chuyện mới
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  ref.read(chatProvider.notifier).startNewChat();
                  Navigator.of(context).pop(); // Đóng Drawer
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Cuộc trò chuyện mới',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            
            const Divider(color: Colors.white24, height: 1),
            
            // Tiêu đề phần lịch sử
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'LỊCH SỬ TRÒ CHUYỆN',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            
            // Danh sách các cuộc trò chuyện cũ
            Expanded(
              child: chatState.isSessionsLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                  : chatState.sessions.isEmpty
                      ? const Center(
                          child: Text(
                            'Chưa có cuộc trò chuyện nào',
                            style: TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          itemCount: chatState.sessions.length,
                          itemBuilder: (context, index) {
                            final session = chatState.sessions[index];
                            final sessionId = session['_id'] ?? '';
                            final title = session['sessionTitle'] ?? 'Cuộc trò chuyện mới';
                            final isActive = sessionId == chatState.activeSessionId;
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isActive 
                                      ? Colors.blueAccent.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: isActive
                                      ? Border.all(color: Colors.blueAccent.withOpacity(0.4))
                                      : null,
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.chat_bubble_outline,
                                    size: 16,
                                    color: isActive ? Colors.blueAccent : Colors.white70,
                                  ),
                                  title: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isActive ? Colors.white : Colors.white70,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.white38),
                                    onPressed: () {
                                      // Hiện dialog xác nhận xóa
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Xóa cuộc trò chuyện'),
                                          content: const Text('Bạn có chắc chắn muốn xóa cuộc trò chuyện này không?'),
                                          actions: [
                                            TextButton(
                                              child: const Text('Hủy'),
                                              onPressed: () => Navigator.of(context).pop(),
                                            ),
                                            TextButton(
                                              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                              onPressed: () {
                                                ref.read(chatProvider.notifier).deleteSession(sessionId);
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  onTap: () {
                                    ref.read(chatProvider.notifier).selectSession(sessionId);
                                    Navigator.of(context).pop(); // Đóng Drawer
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // Bong bóng chat
  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : (isDark ? Theme.of(context).cardColor : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          border: (!isUser && isDark) ? Border.all(color: const Color(0xFF35373C), width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : (isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                fontSize: 15,
              ),
            ),
            if (message.actionData != null && message.actionData!['action'] == 'LOG_WORKOUT') ...[
              const SizedBox(height: 8),
              _buildWorkoutActionWidget(message),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: isUser ? Colors.white70 : (isDark ? const Color(0xFF949BA4) : Colors.black45),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nút hành động Lưu Kcal đã đốt
  Widget _buildWorkoutActionWidget(ChatMessage message) {
    final actionData = message.actionData;
    if (actionData == null) return const SizedBox.shrink();

    final activityName = actionData['activityName'] ?? 'Vận động';
    final duration = (actionData['duration'] is num) 
        ? (actionData['duration'] as num).toDouble() 
        : double.tryParse(actionData['duration']?.toString() ?? '0') ?? 0.0;
    final caloriesBurned = (actionData['caloriesBurned'] is num) 
        ? (actionData['caloriesBurned'] as num).toDouble() 
        : double.tryParse(actionData['caloriesBurned']?.toString() ?? '0') ?? 0.0;

    final isSaved = message.isSaved;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      child: isSaved
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Đã lưu vào nhật ký',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : PurpleGradientButton(
              height: 38,
              onPressed: () async {
                try {
                  // Show loading dialog
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  // 1. Gọi API lưu trực tiếp vào MongoDB
                  final apiService = ApiService();
                  await apiService.logWorkout(
                    activityName: activityName,
                    duration: duration,
                    caloriesBurned: caloriesBurned,
                  );

                  // 2. Cập nhật trạng thái tin nhắn là đã lưu
                  ref.read(chatProvider.notifier).markMessageAsSaved(message.id);

                  // 3. Cập nhật số calo đốt trên Dashboard thông qua Riverpod ngay lập tức
                  await ref.read(healthProvider.notifier).refreshAll();

                  // Ẩn loading
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🔥 Đã lưu thành công $caloriesBurned kcal!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // Ẩn loading
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Lưu ${caloriesBurned.toStringAsFixed(0)} kcal đã đốt',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
    );
  }

  // Hiệu ứng AI đang trả lời: Waving Three Dots cực kỳ cao cấp
  Widget _buildTypingIndicator() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isDark ? Border.all(color: const Color(0xFF35373C), width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.06 : 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ThreeDotsIndicator(),
            const SizedBox(width: 12),
            Text(
              'Trợ lý đang phân tích...',
              style: TextStyle(
                color: isDark ? const Color(0xFFB5BAC1) : Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Khu vực nhập liệu
  Widget _buildInputArea() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDark ? Theme.of(context).cardColor : Colors.white,
      child: TextField(
        controller: _controller,
        style: TextStyle(color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Hỏi về sức khỏe, calo hoặc nhập bài tập (Ví dụ: "chạy bộ 30 phút")...',
          hintStyle: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey, fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1F22) : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          suffixIcon: Container(
            margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B2D31) : Colors.blueAccent,
              shape: BoxShape.circle,
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: const Color(0xFFBB86FC).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: isDark ? const Color(0xFFBB86FC) : Colors.white, size: 18),
              onPressed: _handleSend,
            ),
          ),
        ),
        onSubmitted: (_) => _handleSend(),
      ),
    );
  }

  void _handleSend() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(text);
      _controller.clear();
    }
  }
}

// Widget hiệu ứng 3 chấm động (Three Dots Typing Animation)
class ThreeDotsIndicator extends StatefulWidget {
  const ThreeDotsIndicator({super.key});

  @override
  State<ThreeDotsIndicator> createState() => _ThreeDotsIndicatorState();
}

class _ThreeDotsIndicatorState extends State<ThreeDotsIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final double value = (sin((_controller.value * 2 * pi) - delay) + 1) / 2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.3 + (value * 0.7)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
