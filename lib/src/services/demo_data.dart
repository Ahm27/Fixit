import '../models/chat_models.dart';
import '../models/app_notification.dart';
import '../models/request_job.dart';
import '../models/customer_profile.dart';
import '../models/worker_profile.dart';

class DemoData {
  static CustomerProfile customerProfile([
    String email = 'customer@fixit.app',
  ]) {
    return CustomerProfile(
      id: 'customer-demo-1',
      fullName: 'Mariam Nabil',
      email: email,
      phone: '+20 111 222 3333',
      city: 'Cairo',
    );
  }

  static WorkerProfile workerProfile([String email = 'worker@fixit.app']) {
    return WorkerProfile(
      id: 'worker-demo-1',
      fullName: 'Ahmed Hassan',
      email: email,
      phone: '+20 123 456 7890',
      city: 'Cairo',
      serviceCategory: 'Plumbing',
      yearsExperience: 6,
      nationalId: '29801231234567',
      hourlyRate: 180,
      bio:
          'Verified FixIt worker focused on urgent plumbing, installations, and fast home visits.',
      isAvailable: true,
      rating: 4.8,
      completedJobs: 42,
    );
  }

  static List<WorkerProfile> workers = [
    workerProfile(),
    const WorkerProfile(
      id: 'worker-demo-2',
      fullName: 'Mostafa Ali',
      email: 'mostafa@fixit.app',
      phone: '+20 100 888 4444',
      city: 'Cairo',
      serviceCategory: 'Plumbing',
      yearsExperience: 4,
      nationalId: '29701991234567',
      hourlyRate: 150,
      bio: 'Reliable home visits for faucet installs, leaks, and maintenance.',
      isAvailable: true,
      rating: 4.6,
      completedJobs: 28,
    ),
    const WorkerProfile(
      id: 'worker-demo-3',
      fullName: 'Hassan Mohamed',
      email: 'hassan@fixit.app',
      phone: '+20 101 777 9999',
      city: 'Giza',
      serviceCategory: 'Electrical',
      yearsExperience: 7,
      nationalId: '29504561234567',
      hourlyRate: 210,
      bio:
          'Electrical diagnostics, wiring fixes, and switchboard troubleshooting.',
      isAvailable: true,
      rating: 4.9,
      completedJobs: 61,
    ),
  ];

  static List<RequestJob> requests = [
    RequestJob(
      id: 'req-001',
      customerId: 'customer-demo-1',
      customerName: 'Mariam Nabil',
      customerAddress: 'Nasr City, Cairo',
      title: 'Kitchen sink leak',
      category: 'Plumbing',
      description: 'Water is leaking under the sink and getting worse.',
      scheduledFor: DateTime.now().add(const Duration(hours: 1)),
      estimatedPrice: 220,
      status: RequestStatus.pending,
      threadId: 'thread-001',
      attachmentUrl:
          'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?auto=format&fit=crop&w=900&q=80',
    ),
    RequestJob(
      id: 'req-002',
      customerId: 'customer-002',
      customerName: 'Omar Khaled',
      customerAddress: 'Maadi, Cairo',
      title: 'Water heater check',
      category: 'Plumbing',
      description: 'Heater pressure is low and it makes a noise on startup.',
      scheduledFor: DateTime.now().subtract(const Duration(hours: 2)),
      estimatedPrice: 340,
      status: RequestStatus.inProgress,
      threadId: 'thread-002',
      workerName: 'Ahmed Hassan',
      workerId: 'worker-demo-1',
    ),
    RequestJob(
      id: 'req-003',
      customerId: 'customer-003',
      customerName: 'Salma Adel',
      customerAddress: 'Heliopolis, Cairo',
      title: 'Install new faucet',
      category: 'Plumbing',
      description: 'Need installation for a new bathroom faucet.',
      scheduledFor: DateTime.now().subtract(const Duration(days: 1)),
      estimatedPrice: 180,
      status: RequestStatus.completed,
      threadId: 'thread-003',
      workerName: 'Ahmed Hassan',
      workerId: 'worker-demo-1',
      completedAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    RequestJob(
      id: 'req-004',
      customerId: 'customer-004',
      customerName: 'Youssef Samir',
      customerAddress: 'Dokki, Giza',
      title: 'Pipe replacement',
      category: 'Plumbing',
      description:
          'One damaged section under the bathroom floor needs replacement.',
      scheduledFor: DateTime.now().add(const Duration(days: 1)),
      estimatedPrice: 460,
      status: RequestStatus.accepted,
      threadId: 'thread-004',
      workerName: 'Ahmed Hassan',
      workerId: 'worker-demo-1',
    ),
  ];

  static List<MessageThread> threads = [
    MessageThread(
      id: 'thread-001',
      requestId: 'req-001',
      customerName: 'Mariam Nabil',
      workerName: 'FixIt Dispatch',
      lastMessage: 'Can you arrive before 6 PM?',
      lastMessageAt: DateTime.now().subtract(const Duration(minutes: 12)),
      unreadCount: 2,
      isOnline: true,
    ),
    MessageThread(
      id: 'thread-002',
      requestId: 'req-002',
      customerName: 'Omar Khaled',
      workerName: 'Ahmed Hassan',
      lastMessage: 'I left the building gate open for you.',
      lastMessageAt: DateTime.now().subtract(const Duration(hours: 1)),
      unreadCount: 0,
      isOnline: false,
    ),
    MessageThread(
      id: 'thread-003',
      requestId: 'req-003',
      customerName: 'Salma Adel',
      workerName: 'Ahmed Hassan',
      lastMessage: 'Thanks, everything looks good now.',
      lastMessageAt: DateTime.now().subtract(const Duration(days: 1)),
      unreadCount: 0,
      isOnline: false,
    ),
  ];

  static final Map<String, List<ChatMessage>> messages = {
    'thread-001': [
      ChatMessage(
        id: 'msg-11',
        threadId: 'thread-001',
        senderId: 'customer-demo-1',
        receiverId: 'worker-demo-1',
        body: 'Hi, the leak is getting bigger.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      ChatMessage(
        id: 'msg-12',
        threadId: 'thread-001',
        senderId: 'worker-demo-1',
        receiverId: 'customer-001',
        body: 'I can take this request and head over soon.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      ),
      ChatMessage(
        id: 'msg-13',
        threadId: 'thread-001',
        senderId: 'customer-demo-1',
        receiverId: 'worker-demo-1',
        body: 'Can you arrive before 6 PM?',
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
    ],
    'thread-002': [
      ChatMessage(
        id: 'msg-21',
        threadId: 'thread-002',
        senderId: 'customer-002',
        receiverId: 'worker-demo-1',
        body: 'I left the building gate open for you.',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
    ],
    'thread-003': [
      ChatMessage(
        id: 'msg-31',
        threadId: 'thread-003',
        senderId: 'customer-003',
        receiverId: 'worker-demo-1',
        body: 'Thanks, everything looks good now.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ],
  };

  static List<AppNotification> notificationsFor(
    String userId, {
    required bool isWorker,
  }) {
    if (isWorker) {
      return [
        AppNotification(
          id: 'notif-worker-1',
          userId: userId,
          title: 'New nearby request',
          body: 'Mariam needs help with a kitchen sink leak in Nasr City.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 9)),
          type: AppNotificationType.request,
          requestId: 'req-001',
          threadId: 'thread-001',
        ),
        AppNotification(
          id: 'notif-worker-2',
          userId: userId,
          title: 'Payout updated',
          body: 'Your available balance increased after a completed booking.',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          type: AppNotificationType.earning,
        ),
      ];
    }

    return [
      AppNotification(
        id: 'notif-customer-1',
        userId: userId,
        title: 'Worker accepted your request',
        body: 'Ahmed Hassan accepted your water heater service booking.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        type: AppNotificationType.request,
        requestId: 'req-002',
        threadId: 'thread-002',
      ),
      AppNotification(
        id: 'notif-customer-2',
        userId: userId,
        title: 'New message',
        body: 'A worker sent a new update in your service chat.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        type: AppNotificationType.message,
        threadId: 'thread-001',
      ),
    ];
  }
}
