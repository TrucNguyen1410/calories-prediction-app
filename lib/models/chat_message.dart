import 'dart:convert';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isActionable;
  final String? actionType;
  final Map<String, dynamic>? actionData;
  final bool isSaved;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isActionable = false,
    this.actionType,
    this.actionData,
    this.isSaved = false,
  });

  // Chuyển từ JSON (nhận từ API) sang Object
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? json['_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      text: json['text'] ?? json['content'] ?? '',
      isUser: json['isUser'] ?? (json['role'] == 'user') ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      isActionable: json['isActionable'] ?? false,
      actionType: json['actionType'],
      actionData: json['actionData'] != null && json['actionData'] is Map
          ? Map<String, dynamic>.from(json['actionData']) 
          : null,
      isSaved: json['isSaved'] ?? false,
    );
  }

  // Chuyển từ Object sang JSON (để lưu trữ hoặc gửi đi)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isActionable': isActionable,
      'actionType': actionType,
      'actionData': actionData,
      'isSaved': isSaved,
    };
  }

  // Tạo một bản sao tin nhắn (hữu ích cho State management)
  ChatMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isActionable,
    String? actionType,
    Map<String, dynamic>? actionData,
    bool? isSaved,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isActionable: isActionable ?? this.isActionable,
      actionType: actionType ?? this.actionType,
      actionData: actionData ?? this.actionData,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
