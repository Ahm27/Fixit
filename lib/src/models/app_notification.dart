enum AppNotificationType { request, message, earning, system }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
    this.isRead = false,
    this.requestId,
    this.threadId,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;
  final AppNotificationType type;
  final bool isRead;
  final String? requestId;
  final String? threadId;

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    DateTime? createdAt,
    AppNotificationType? type,
    bool? isRead,
    String? requestId,
    String? threadId,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      requestId: requestId ?? this.requestId,
      threadId: threadId ?? this.threadId,
    );
  }
}
