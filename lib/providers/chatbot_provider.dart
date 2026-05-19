import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatbotState {
  final double x;
  final double y;
  final bool isChatOpen;
  final bool isDragging;

  ChatbotState({
    required this.x,
    required this.y,
    required this.isChatOpen,
    required this.isDragging,
  });

  ChatbotState copyWith({
    double? x,
    double? y,
    bool? isChatOpen,
    bool? isDragging,
  }) {
    return ChatbotState(
      x: x ?? this.x,
      y: y ?? this.y,
      isChatOpen: isChatOpen ?? this.isChatOpen,
      isDragging: isDragging ?? this.isDragging,
    );
  }
}

class ChatbotNotifier extends StateNotifier<ChatbotState> {
  ChatbotNotifier()
      : super(ChatbotState(
          x: -1.0, // Indication to set initial position on first build
          y: -1.0,
          isChatOpen: false,
          isDragging: false,
        ));

  void initializePosition(double initialX, double initialY) {
    if (state.x == -1.0 && state.y == -1.0) {
      state = state.copyWith(x: initialX, y: initialY);
    }
  }

  void updatePosition(double dx, double dy, double screenWidth, double screenHeight, double iconSize) {
    final currentX = state.x == -1.0 ? screenWidth - iconSize - 20.0 : state.x;
    final currentY = state.y == -1.0 ? screenHeight - iconSize - 100.0 : state.y;

    final newX = (currentX + dx).clamp(10.0, screenWidth - iconSize - 10.0);
    final newY = (currentY + dy).clamp(50.0, screenHeight - iconSize - 120.0); // Safe vertical area

    state = state.copyWith(x: newX, y: newY, isDragging: true);
  }

  void endDragging(double screenWidth, double iconSize) {
    final currentX = state.x == -1.0 ? screenWidth - iconSize - 20.0 : state.x;
    final middle = screenWidth / 2;
    
    // Snapping behavior: side with closer proximity to screen edge
    final finalX = (currentX + iconSize / 2 < middle)
        ? 10.0
        : screenWidth - iconSize - 10.0;

    state = state.copyWith(x: finalX, isDragging: false);
  }

  void toggleChatOpen() {
    state = state.copyWith(isChatOpen: !state.isChatOpen);
  }

  void setChatOpen(bool isOpen) {
    state = state.copyWith(isChatOpen: isOpen);
  }
}

final chatbotProvider = StateNotifierProvider<ChatbotNotifier, ChatbotState>((ref) {
  return ChatbotNotifier();
});
