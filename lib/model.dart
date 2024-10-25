class ChatMessage {
  final bool isMe;
  String text;
  final DateTime sentAt;

  ChatMessage({
    required this.isMe,
    required this.text,
    required this.sentAt,
  });
}

class ChatRoom {
  List<ChatMessage> chats;
  final DateTime createdAt;

  ChatRoom({
    required this.chats,
    required this.createdAt,
  });
}