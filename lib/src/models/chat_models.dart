class MessageThread {
  const MessageThread({
    required this.id,
    required this.requestId,
    required this.customerName,
    required this.workerName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
    required this.isOnline,
  });

  final String id;
  final String requestId;
  final String customerName;
  final String workerName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isOnline;

  String initialsFor(bool isWorkerView) {
    final parts = (isWorkerView ? customerName : workerName)
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'FX';
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  String counterpartFor(bool isWorkerView) {
    return isWorkerView ? customerName : workerName;
  }

  MessageThread copyWith({
    String? id,
    String? requestId,
    String? customerName,
    String? workerName,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? isOnline,
  }) {
    return MessageThread(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      customerName: customerName ?? this.customerName,
      workerName: workerName ?? this.workerName,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.receiverId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String threadId;
  final String senderId;
  final String receiverId;
  final String body;
  final DateTime createdAt;
}
