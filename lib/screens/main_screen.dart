import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../models/chat_message.dart';
import 'home_screen.dart';
import 'stats_screen.dart';
import 'predict_screen.dart';
import 'profile_screen.dart';
import '../theme.dart';

class MainScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? userData;

  const MainScreen({Key? key, this.userData}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  bool _isChatOpen = false;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const StatsScreen(),
      const PredictScreen(),
      ProfileScreen(
        name: widget.userData?["name"] ?? "Người dùng",
        email: widget.userData?["email"] ?? "Không xác định",
      ),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
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
    if (chatState.messages.isNotEmpty || chatState.isLoading) {
      _scrollToBottom();
    }

    return Scaffold(
      body: Stack(
        children: [
          // Lớp dưới: Giao diện chính
          Scaffold(
            body: _screens[_selectedIndex],
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primary,
              unselectedItemColor: Colors.grey,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Trang chủ"),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), label: "Thống kê"),
                BottomNavigationBarItem(icon: Icon(Icons.fitness_center_outlined), label: "Dự đoán"),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Cá nhân"),
              ],
            ),
          ),

          // Lớp trên: Popup Chat AI
          if (_isChatOpen)
            Positioned(
              bottom: 90,
              right: 20,
              child: _buildChatPopup(chatState),
            ),

          // Nút Floating Action Button điều khiển Popup
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () => setState(() => _isChatOpen = !_isChatOpen),
              backgroundColor: _isChatOpen ? Colors.grey : AppTheme.primary,
              elevation: 4,
              child: Icon(
                _isChatOpen ? Icons.close : Icons.smart_toy_outlined,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatPopup(chatState) {
    return Container(
      width: 350,
      height: 550,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Header của Card
          _buildPopupHeader(),
          
          // Body - Danh sách tin nhắn
          Expanded(
            child: Container(
              color: Colors.grey[50],
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
            onPressed: () => setState(() => _isChatOpen = false),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : Colors.white,
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
              style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(color: isUser ? Colors.white70 : Colors.black45, fontSize: 9),
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Hỏi AI...',
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
              onSubmitted: (_) => _handleChatSend(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: AppTheme.primary),
            onPressed: _handleChatSend,
          ),
        ],
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
