import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../providers/chatbot_provider.dart';
import '../models/chat_message.dart';
import '../providers/health_provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'menu_screen.dart';
import 'profile_screen.dart';
import '../theme.dart';
import '../providers/tour_provider.dart';

final mainTabProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? userData;

  const MainScreen({Key? key, this.userData}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const MenuScreen(),
      const StatsScreen(),
      ProfileScreen(
        name: widget.userData?["name"] ?? "Người dùng",
        email: widget.userData?["email"] ?? "Không xác định",
      ),
    ];
  }

  void _onItemTapped(int index) {
    ref.read(mainTabProvider.notifier).state = index;
  }

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
    final chatbotState = ref.watch(chatbotProvider);
    final chatbotNotifier = ref.read(chatbotProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (chatState.messages.isNotEmpty || chatState.isLoading) {
      _scrollToBottom();
    }

    final screenSize = MediaQuery.of(context).size;
    const double iconSize = 50.0; // Perfect visual size for the circular logo

    // Khởi tạo vị trí ban đầu (góc dưới bên phải, ngay trên BottomNavigationBar)
    if (chatbotState.x == -1.0 && chatbotState.y == -1.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        chatbotNotifier.initializePosition(
          screenSize.width - iconSize - 20.0,
          screenSize.height - iconSize - 100.0,
        );
      });
    }

    // Luôn giới hạn tọa độ (clamp) theo kích thước màn hình hiện tại để tránh bị tràn/mất icon khi F12/xoay màn hình
    final currentX = (chatbotState.x == -1.0 ? screenSize.width - iconSize - 20.0 : chatbotState.x)
        .clamp(10.0, screenSize.width - iconSize - 10.0);
    final currentY = (chatbotState.y == -1.0 ? screenSize.height - iconSize - 100.0 : chatbotState.y)
        .clamp(50.0, screenSize.height - iconSize - 120.0);

    return Scaffold(
      body: Stack(
        children: [
          // Lớp dưới: Giao diện chính
          Scaffold(
            body: _screens[ref.watch(mainTabProvider)],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: ref.watch(mainTabProvider),
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: Colors.grey,
              items: [
                const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Trang chủ"),
                BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu_outlined, key: ref.read(tourKeysProvider).menuTabKey), label: "Thực đơn"),
                const BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: "Thống kê"),
                const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Cá nhân"),
              ],
            ),
          ),

          // Lớp trên: Popup Chat AI (Cố định góc dưới bên phải như yêu cầu)
          if (chatbotState.isChatOpen)
            Positioned(
              bottom: 20,
              right: 20,
              child: _buildChatPopup(chatState),
            ),

          // Nút Floating Chatbot (Có thể kéo thả và tự động hút về mép khi thả ra)
          if (!chatbotState.isChatOpen) // Ẩn khi khung chat mở để nhường chỗ
            AnimatedPositioned(
              duration: chatbotState.isDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 350),
              curve: Curves.easeOutBack, // Hiệu ứng snap đàn hồi cực chất
              left: currentX,
              top: currentY,
              child: GestureDetector(
                onPanUpdate: (details) {
                  chatbotNotifier.updatePosition(
                    details.delta.dx,
                    details.delta.dy,
                    screenSize.width,
                    screenSize.height,
                    iconSize,
                  );
                },
                onPanEnd: (_) {
                  chatbotNotifier.endDragging(screenSize.width, iconSize);
                },
                onTap: () {
                  chatbotNotifier.setChatOpen(true);
                },
                child: Container(
                  key: ref.read(tourKeysProvider).chatbotKey,
                  width: iconSize,
                  height: iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF1E1F22) : Colors.white,
                    border: Border.all(color: isDark ? const Color(0xFFBB86FC) : AppTheme.primary, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                            ? const Color(0xFFBB86FC).withOpacity(0.5) 
                            : Colors.black.withOpacity(0.18),
                        blurRadius: isDark ? 15 : 10,
                        spreadRadius: isDark ? 2 : 0,
                        offset: isDark ? Offset.zero : const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/chatbot_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: isDark ? const Color(0xFF1E1F22) : Colors.white,
                          child: Icon(
                            Icons.smart_toy_outlined,
                            color: isDark ? const Color(0xFFBB86FC) : AppTheme.primary,
                            size: 32,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatPopup(chatState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      width: 350,
      height: 550,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          // Header của Card
          _buildPopupHeader(),
          
          // Body - Danh sách tin nhắn
          Expanded(
            child: Container(
              color: isDark ? const Color(0xFF1E1F22) : Colors.grey[50],
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(12),
                itemCount: chatState.messages.length + (chatState.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == chatState.messages.length) {
                    return _buildTypingIndicator();
                  }
                  return _buildChatBubble(chatState.messages[index]);
                },
              ),
            ),
          ),

          // Hiển thị lỗi nếu có
          if (chatState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                chatState.error!,
                style: const TextStyle(color: Colors.red, fontSize: 10),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Footer - Ô nhập liệu
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildPopupHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Trợ lý Sức khỏe AI',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white70, size: 20),
            onPressed: () => ref.read(chatProvider.notifier).clearChat(),
            tooltip: 'Xóa hội thoại',
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () => ref.read(chatbotProvider.notifier).setChatOpen(false),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : (isDark ? const Color(0xFF35373C) : Colors.white),
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? Radius.zero : null,
            bottomLeft: !isUser ? Radius.zero : null,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2),
          ],
        ),
        constraints: const BoxConstraints(maxWidth: 250),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isUser ? Colors.white : (isDark ? const Color(0xFFF2F3F5) : Colors.black87),
                fontSize: 14,
              ),
            ),
            if (message.actionData != null && message.actionData!['action'] == 'LOG_WORKOUT') ...[
              const SizedBox(height: 8),
              _buildWorkoutActionWidget(message),
            ],
            const SizedBox(height: 2),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(
                color: isUser ? Colors.white70 : (isDark ? const Color(0xFF949BA4) : Colors.black45),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          : ElevatedButton.icon(
              onPressed: () async {
                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );

                  final apiService = ApiService();
                  await apiService.logWorkout(
                    activityName: activityName,
                    duration: duration,
                    caloriesBurned: caloriesBurned,
                  );

                  ref.read(chatProvider.notifier).markMessageAsSaved(message.id);
                  await ref.read(healthProvider.notifier).refreshAll();

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
              icon: const Icon(Icons.local_fire_department, size: 16, color: Colors.white),
              label: Text('Lưu ${caloriesBurned.toStringAsFixed(0)} kcal đã đốt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 0,
              ),
            ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
            Text('Trợ lý đang trả lời...', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: TextField(
        controller: _chatController,
        style: TextStyle(fontSize: 14, color: isDark ? const Color(0xFFF2F3F5) : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Hỏi AI...',
          hintStyle: TextStyle(color: isDark ? const Color(0xFF949BA4) : Colors.grey[500]),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1F22) : Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
          suffixIcon: Container(
            margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B2D31) : Colors.transparent,
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
              icon: Icon(Icons.send, color: isDark ? const Color(0xFFBB86FC) : AppTheme.primary, size: 18),
              onPressed: _handleChatSend,
            ),
          ),
        ),
        onSubmitted: (_) => _handleChatSend(),
      ),
    );
  }

  void _handleChatSend() {
    final text = _chatController.text.trim();
    if (text.isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(text);
      _chatController.clear();
    }
  }
}
