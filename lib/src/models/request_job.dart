enum RequestStatus { pending, accepted, inProgress, completed, cancelled }

class RequestJob {
  const RequestJob({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerAddress,
    required this.title,
    required this.category,
    required this.description,
    required this.scheduledFor,
    required this.estimatedPrice,
    required this.status,
    required this.threadId,
    this.workerName,
    this.workerId,
    this.attachmentUrl,
    this.completedAt,
  });

  final String id;
  final String customerId;
  final String customerName;
  final String customerAddress;
  final String title;
  final String category;
  final String description;
  final DateTime scheduledFor;
  final double estimatedPrice;
  final RequestStatus status;
  final String threadId;
  final String? workerName;
  final String? workerId;
  final String? attachmentUrl;
  final DateTime? completedAt;

  RequestJob copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? customerAddress,
    String? title,
    String? category,
    String? description,
    DateTime? scheduledFor,
    double? estimatedPrice,
    RequestStatus? status,
    String? threadId,
    String? workerName,
    String? workerId,
    String? attachmentUrl,
    DateTime? completedAt,
  }) {
    return RequestJob(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerAddress: customerAddress ?? this.customerAddress,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      status: status ?? this.status,
      threadId: threadId ?? this.threadId,
      workerName: workerName ?? this.workerName,
      workerId: workerId ?? this.workerId,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
