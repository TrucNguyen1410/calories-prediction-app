import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import 'dart:convert';

import '../models/chat_message.dart';
import '../services/api_service.dart';

// Model để quản lý State của toàn bộ màn hình Chat
class ChatState {
  final List<ChatMessage> messages;
  final List<Map<String, dynamic>> sessions; // Danh sách các phiên trò chuyện lịch sử
  final String? activeSessionId; // ID cuộc trò chuyện hiện tại
  final bool isLoading;
  final bool isSessionsLoading;
  final String? error;

  ChatState({
    required this.messages,
    required this.sessions,
    this.activeSessionId,
    required this.isLoading,
    required this.isSessionsLoading,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    List<Map<String, dynamic>>? sessions,
    String? activeSessionId,
    bool? isLoading,
    bool? isSessionsLoading,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      sessions: sessions ?? this.sessions,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      isLoading: isLoading ?? this.isLoading,
      isSessionsLoading: isSessionsLoading ?? this.isSessionsLoading,
      error: error,
    );
  }
}

// StateNotifier để xử lý logic thay đổi State
class ChatNotifier extends StateNotifier<ChatState> {
  final ApiService _apiService = ApiService();

  ChatNotifier() : super(ChatState(
    messages: [], 
    sessions: [], 
    activeSessionId: null, 
    isLoading: false, 
    isSessionsLoading: false
  )) {
    // Tự động load danh sách lịch sử khi khởi động
    loadSessions();
  }

  // Tải danh sách tất cả cuộc hội thoại
  Future<void> loadSessions() async {
    state = state.copyWith(isSessionsLoading: true, error: null);
    try {
      final list = await _apiService.getChatSessions();
      state = state.copyWith(sessions: list, isSessionsLoading: false);
    } catch (e) {
      state = state.copyWith(isSessionsLoading: false, error: e.toString());
    }
  }

  // Chọn một cuộc hội thoại cụ thể để tiếp tục chat
  Future<void> selectSession(String sessionId) async {
    state = state.copyWith(isLoading: true, activeSessionId: sessionId, messages: [], error: null);
    try {
      final detail = await _apiService.getChatSessionDetail(sessionId);
      if (detail['success'] == true && detail['messages'] != null) {
        final list = (detail['messages'] as List).map((msg) => ChatMessage.fromJson(msg)).toList();
        state = state.copyWith(
          messages: list,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Không thể tải lịch sử tin nhắn');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Khởi tạo cuộc trò chuyện mới tinh
  Future<void> startNewChat() async {
    state = state.copyWith(isLoading: true, messages: [], activeSessionId: null, error: null);
    try {
      final res = await _apiService.createChatSession();
      if (res['success'] == true && res['session'] != null) {
        final newSession = res['session'];
        final newSessionId = newSession['_id'];
        
        state = state.copyWith(
          activeSessionId: newSessionId,
          isLoading: false,
          messages: [],
        );
        await loadSessions();
      } else {
        state = state.copyWith(isLoading: false, error: 'Không thể khởi tạo cuộc trò chuyện mới');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Xóa một cuộc hội thoại lịch sử
  Future<void> deleteSession(String sessionId) async {
    state = state.copyWith(isSessionsLoading: true, error: null);
    try {
      final ok = await _apiService.deleteChatSession(sessionId);
      if (ok) {
        await loadSessions();
        if (state.activeSessionId == sessionId) {
          // Nếu đang mở cuộc vừa bị xóa, đưa về trạng thái trắng
          state = state.copyWith(messages: [], activeSessionId: null);
        }
      } else {
        state = state.copyWith(isSessionsLoading: false, error: 'Lỗi khi xóa cuộc trò chuyện');
      }
    } catch (e) {
      state = state.copyWith(isSessionsLoading: false, error: e.toString());
    }
  }

  // Hàm gửi tin nhắn (Tích hợp Session)
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Tự động tạo phiên chat mới nếu chưa có phiên active
    if (state.activeSessionId == null) {
      state = state.copyWith(isLoading: true);
      try {
        final res = await _apiService.createChatSession();
        if (res['success'] == true && res['session'] != null) {
          state = state.copyWith(activeSessionId: res['session']['_id']);
        } else {
          state = state.copyWith(isLoading: false, error: 'Không thể tự động tạo phiên chat mới');
          return;
        }
      } catch (e) {
        state = state.copyWith(isLoading: false, error: e.toString());
        return;
      }
    }

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
      // 2. Gọi API gửi tới Gemini/Groq
      final aiRes = await _apiService.sendMessageToAI(text, sessionId: state.activeSessionId);
      final aiReplyRaw = aiRes['reply'] ?? '';
      
      String displayText = aiReplyRaw;
      bool isActionable = false;
      String? actionType;
      Map<String, dynamic>? actionData;

      try {
        String cleanedText = aiReplyRaw.trim();
        
        // Dùng Regex trích xuất khối JSON bên trong phản hồi của AI
        final jsonRegExp = RegExp(r'\{[\s\S]*\}');
        final match = jsonRegExp.firstMatch(cleanedText);
        
        if (match != null) {
          final jsonString = match.group(0)!;
          final parsedJson = jsonDecode(jsonString);
          
          if (parsedJson is Map<String, dynamic> && parsedJson['action'] == 'LOG_WORKOUT') {
            displayText = parsedJson['message'] ?? 'Đã ghi nhận bài tập của bạn!';
            isActionable = true;
            actionType = 'LOG_WORKOUT';
            actionData = parsedJson;
          }
        }
      } catch (e) {
        // Fallback: nếu lỗi parse JSON thì giữ nguyên tin nhắn gốc (không có action)
      }

      // 3. Tạo tin nhắn của AI và thêm vào danh sách
      final aiMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        text: displayText,
        isUser: false,
        timestamp: DateTime.now(),
        isActionable: isActionable,
        actionType: actionType,
        actionData: actionData,
        isSaved: false,
      );

      state = state.copyWith(
        messages: [...state.messages, aiMessage],
        isLoading: false,
      );
      
      // Load lại lịch sử để cập nhật tiêu đề cuộc trò chuyện
      await loadSessions();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Cập nhật trạng thái đã lưu cho tin nhắn
  void markMessageAsSaved(String messageId) {
    state = state.copyWith(
      messages: state.messages.map((msg) {
        if (msg.id == messageId) {
          return msg.copyWith(isSaved: true);
        }
        return msg;
      }).toList(),
    );
  }

  // Hàm xóa lịch sử chat cục bộ
  void clearChat() {
    state = ChatState(
      messages: [], 
      sessions: state.sessions, 
      activeSessionId: state.activeSessionId, 
      isLoading: false,
      isSessionsLoading: false
    );
  }
}

// Provider toàn cục để UI lắng nghe
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier();
});
