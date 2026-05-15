import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import '../models/chat_message.dart';
import '../services/api_service.dart';

// Model để quản lý State của toàn bộ màn hình Chat
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final String? error;

  ChatState({
    required this.messages,
    required this.isLoading,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Nếu error null thì clear error cũ
    );
  }
}

// StateNotifier để xử lý logic thay đổi State
class ChatNotifier extends StateNotifier<ChatState> {
  final ApiService _apiService = ApiService();

  ChatNotifier() : super(ChatState(messages: [], isLoading: false));

  // Hàm gửi tin nhắn
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Tạo tin nhắn của User và thêm vào danh sách
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isLoading: true,
      error: null,
    );

    try {
      // 2. Gọi API gửi tới Gemini
      final aiReplyText = await _apiService.sendMessageToAI(text);

      // 3. Tạo tin nhắn của AI và thêm vào danh sách
      final aiMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: aiReplyText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
    } catch (e) {
      // 4. Xử lý lỗi
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Hàm xóa lịch sử chat (nếu cần)
  void clearChat() {
    state = ChatState(messages: [], isLoading: false);
  }
}

// Provider toàn cục để UI lắng nghe
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
