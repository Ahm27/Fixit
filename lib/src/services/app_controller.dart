import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import '../l10n/app_strings.dart';
import '../models/account_role.dart';
import '../models/app_notification.dart';
import '../models/chat_models.dart';
import '../models/customer_profile.dart';
import '../models/customer_signup_data.dart';
import '../models/earnings_summary.dart';
import '../models/request_job.dart';
import '../models/worker_profile.dart';
import '../models/worker_signup_data.dart';
import 'demo_data.dart';

class AppController extends ChangeNotifier {
  SupabaseClient? _client;
  bool _isDemoMode = !EnvConfig.hasSupabase;
  bool _isBusy = false;
  String? _errorMessage;
  AccountRole? _currentRole;
  WorkerProfile? _workerProfile;
  CustomerProfile? _customerProfile;
  bool _needsProfileCompletion = false;
  String? _activeThreadId;
  User? _pendingAuthUser;
  AccountRole? _pendingNewUserRole;
  AppLanguage _language = AppLanguage.english;
  StreamSubscription<AuthState>? _authStateSubscription;
  RealtimeChannel? _activeThreadChannel;

  final List<RequestJob> _requests = <RequestJob>[];
  final List<MessageThread> _threads = <MessageThread>[];
  final Map<String, List<ChatMessage>> _messages =
      <String, List<ChatMessage>>{};
  final List<WorkerProfile> _availableWorkers = <WorkerProfile>[];
  final List<AppNotification> _notifications = <AppNotification>[];
  final List<RealtimeChannel> _channels = <RealtimeChannel>[];
  final Set<String> _sendingThreadIds = <String>{};

  final List<String> serviceCategories = const <String>[
    'Plumbing',
    'Electrical',
    'AC Repair',
    'Painting',
    'Carpentry',
    'Appliance Repair',
  ];

  bool get isDemoMode => _isDemoMode;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentRole != null && !_needsProfileCompletion;
  bool get needsProfileCompletion => _needsProfileCompletion;
  AppLanguage get language => _language;
  AppStrings get strings => AppStrings(_language);
  AccountRole? get currentRole => _currentRole;
  WorkerProfile? get workerProfile => _workerProfile;
  CustomerProfile? get customerProfile => _customerProfile;
  SupabaseClient? get client => _client;
  bool get isArabic => _language.isArabic;
  String get pendingEmail => _pendingAuthUser?.email ?? '';
  String get pendingFullName {
    final data = _pendingAuthUser?.userMetadata;
    return (data?['full_name'] as String?) ?? (data?['name'] as String?) ?? '';
  }

  String get pendingAvatarUrl {
    final data = _pendingAuthUser?.userMetadata;
    return (data?['avatar_url'] as String?) ??
        (data?['picture'] as String?) ??
        '';
  }

  AccountRole get pendingRole => _pendingNewUserRole ?? AccountRole.customer;
  List<WorkerProfile> get availableWorkers =>
      List<WorkerProfile>.unmodifiable(_availableWorkers);
  bool isSendingMessage(String threadId) =>
      _sendingThreadIds.contains(threadId);
  List<AppNotification> get notifications {
    final items = _notifications.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List<AppNotification>.unmodifiable(items);
  }

  int get unreadNotificationCount =>
      _notifications.where((item) => !item.isRead).length;

  void setLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }
    _language = language;
    Intl.defaultLocale = language.locale.toLanguageTag();
    notifyListeners();
  }

  Future<void> bootstrap() async {
    _seedDemoCollections();

    if (!EnvConfig.hasSupabase) {
      notifyListeners();
      return;
    }

    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        anonKey: EnvConfig.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
      );
      _client = Supabase.instance.client;
      _isDemoMode = false;
      _authStateSubscription = _client!.auth.onAuthStateChange.listen((
        data,
      ) async {
        final session = data.session;
        switch (data.event) {
          case AuthChangeEvent.signedIn:
          case AuthChangeEvent.userUpdated:
          case AuthChangeEvent.tokenRefreshed:
          case AuthChangeEvent.initialSession:
            if (session?.user != null) {
              await _loadCurrentProfile(
                session!.user.id,
                authUser: session.user,
              );
            }
            break;
          case AuthChangeEvent.signedOut:
            _currentRole = null;
            _customerProfile = null;
            _workerProfile = null;
            _needsProfileCompletion = false;
            _pendingAuthUser = null;
            _pendingNewUserRole = null;
            notifyListeners();
            break;
          case AuthChangeEvent.passwordRecovery:
          case AuthChangeEvent.mfaChallengeVerified:
            break;
          default:
            break;
        }
      });

      try {
        final session = _client!.auth.currentSession;
        if (session != null) {
          await _loadCurrentProfile(session.user.id, authUser: session.user);
        }
      } catch (_) {
        await _client?.auth.signOut();
        _currentRole = null;
        _customerProfile = null;
        _workerProfile = null;
        _needsProfileCompletion = false;
      }
    } catch (_) {
      _isDemoMode = true;
      _errorMessage = 'Supabase setup failed. The app is running in demo mode.';
    }

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  List<RequestJob> get customerRequests {
    if (_customerProfile == null) {
      return const <RequestJob>[];
    }
    return _requests
        .where((job) => job.customerId == _customerProfile!.id)
        .toList()
      ..sort((a, b) => b.scheduledFor.compareTo(a.scheduledFor));
  }

  List<RequestJob> get workerRequests {
    if (_workerProfile == null) {
      return const <RequestJob>[];
    }
    final workerId = _workerProfile!.id;
    return _requests.where((job) {
      final isOpenRequest =
          job.status == RequestStatus.pending && job.workerId == null;
      final isAssignedToCurrentWorker = job.workerId == workerId;
      return isOpenRequest || isAssignedToCurrentWorker;
    }).toList()..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
  }

  List<MessageThread> get visibleThreads {
    if (_currentRole == null) {
      return const <MessageThread>[];
    }
    if (_currentRole == AccountRole.worker && _workerProfile != null) {
      final workerId = _workerProfile!.id;
      final allowedIds = _requests
          .where((job) {
            final isOpenRequest =
                job.status == RequestStatus.pending && job.workerId == null;
            final isAssignedToCurrentWorker = job.workerId == workerId;
            return isOpenRequest || isAssignedToCurrentWorker;
          })
          .map((job) => job.threadId)
          .where((id) => id.isNotEmpty)
          .toSet();
      return _threads.where((thread) => allowedIds.contains(thread.id)).toList()
        ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    }
    if (_currentRole == AccountRole.customer && _customerProfile != null) {
      final allowedIds = _requests
          .where((job) => job.customerId == _customerProfile!.id)
          .map((job) => job.threadId)
          .where((id) => id.isNotEmpty)
          .toSet();
      return _threads.where((thread) => allowedIds.contains(thread.id)).toList()
        ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    }
    return const <MessageThread>[];
  }

  List<ChatMessage> messagesFor(String threadId) {
    final items = _messages[threadId] ?? const <ChatMessage>[];
    return items.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  List<WorkerProfile> workersForCategory(String category) {
    return _availableWorkers
        .where(
          (worker) =>
              worker.serviceCategory.toLowerCase() == category.toLowerCase() &&
              worker.isAvailable,
        )
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }

  bool hasAvailableWorkersForCategory(String category) {
    return workersForCategory(category).isNotEmpty;
  }

  EarningsSummary get earningsSummary {
    if (_workerProfile == null) {
      return const EarningsSummary(
        today: 0,
        thisWeek: 0,
        thisMonth: 0,
        availableBalance: 0,
        completedJobs: 0,
        averageTicket: 0,
      );
    }

    final now = DateTime.now();
    final completed = _requests.where((job) {
      return job.workerId == _workerProfile!.id &&
          job.status == RequestStatus.completed;
    }).toList();

    final today = completed
        .where((job) => _isSameDay(_earningsDateFor(job), now))
        .fold<double>(0, (sum, job) => sum + job.estimatedPrice);
    final thisWeek = completed
        .where((job) => now.difference(_earningsDateFor(job)).inDays < 7)
        .fold<double>(0, (sum, job) => sum + job.estimatedPrice);
    final thisMonth = completed
        .where(
          (job) =>
              _earningsDateFor(job).month == now.month &&
              _earningsDateFor(job).year == now.year,
        )
        .fold<double>(0, (sum, job) => sum + job.estimatedPrice);
    final total = completed.fold<double>(
      0,
      (sum, job) => sum + job.estimatedPrice,
    );

    return EarningsSummary(
      today: today,
      thisWeek: thisWeek,
      thisMonth: thisMonth,
      availableBalance: total,
      completedJobs: completed.length,
      averageTicket: completed.isEmpty ? 0 : total / completed.length,
    );
  }

  Future<void> continueWithGoogle({required AccountRole preferredRole}) async {
    await _runBusy(() async {
      _errorMessage = null;
      if (_isDemoMode) {
        final demoEmail = preferredRole == AccountRole.worker
            ? 'worker@fixit.app'
            : 'customer@fixit.app';
        if (preferredRole == AccountRole.worker) {
          _workerProfile = DemoData.workerProfile(demoEmail);
          _customerProfile = null;
          _notifications
            ..clear()
            ..addAll(
              DemoData.notificationsFor(_workerProfile!.id, isWorker: true),
            );
        } else {
          _customerProfile = DemoData.customerProfile(demoEmail);
          _workerProfile = null;
          _notifications
            ..clear()
            ..addAll(
              DemoData.notificationsFor(_customerProfile!.id, isWorker: false),
            );
        }
        _currentRole = preferredRole;
        _availableWorkers
          ..clear()
          ..addAll(DemoData.workers);
        return;
      }
      _pendingNewUserRole = preferredRole;
      final launched = await _client!.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : EnvConfig.oauthRedirectUrl,
      );
      if (!launched) {
        throw Exception('Could not launch Google sign-in.');
      }
    });
  }

  Future<void> signUpCustomer(CustomerSignupData data) async {
    await _runBusy(() async {
      if (_isDemoMode) {
        _customerProfile = CustomerProfile(
          id: 'customer-${DateTime.now().millisecondsSinceEpoch}',
          fullName: data.fullName,
          email: data.email,
          phone: data.phone,
          city: data.city,
        );
        _workerProfile = null;
        _currentRole = AccountRole.customer;
        _availableWorkers
          ..clear()
          ..addAll(DemoData.workers);
        _notifications
          ..clear()
          ..addAll(
            DemoData.notificationsFor(_customerProfile!.id, isWorker: false),
          );
        return;
      }

      final response = await _client!.auth.signUp(
        email: data.email,
        password: data.password,
        data: <String, dynamic>{
          'role': AccountRole.customer.dbValue,
          'full_name': data.fullName,
          'email': data.email,
          'phone': data.phone,
          'city': data.city,
        },
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Could not create the customer account.');
      }

      if (response.session == null) {
        throw Exception(
          'Account created. If email confirmation is enabled, verify your email then sign in.',
        );
      }

      await _loadCurrentProfile(user.id);
    });
  }

  Future<void> signUpWorker(WorkerSignupData data) async {
    await _runBusy(() async {
      if (_isDemoMode) {
        _workerProfile = WorkerProfile(
          id: 'worker-${DateTime.now().millisecondsSinceEpoch}',
          fullName: data.fullName,
          email: data.email,
          phone: data.phone,
          city: data.city,
          serviceCategory: data.serviceCategory,
          yearsExperience: data.yearsExperience,
          nationalId: data.nationalId,
          hourlyRate: data.hourlyRate,
          bio: data.bio,
          isAvailable: true,
          rating: 4.8,
          completedJobs: 0,
        );
        _customerProfile = null;
        _currentRole = AccountRole.worker;
        _availableWorkers
          ..clear()
          ..addAll(<WorkerProfile>[...DemoData.workers, _workerProfile!]);
        _notifications
          ..clear()
          ..addAll(
            DemoData.notificationsFor(_workerProfile!.id, isWorker: true),
          );
        return;
      }

      final response = await _client!.auth.signUp(
        email: data.email,
        password: data.password,
        data: <String, dynamic>{
          'role': AccountRole.worker.dbValue,
          'full_name': data.fullName,
          'email': data.email,
          'phone': data.phone,
          'city': data.city,
          'service_category': data.serviceCategory,
          'years_experience': data.yearsExperience,
          'national_id': data.nationalId,
          'hourly_rate': data.hourlyRate,
          'bio': data.bio,
        },
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Could not create the worker account.');
      }

      if (response.session == null) {
        throw Exception(
          'Account created. If email confirmation is enabled, verify your email then sign in.',
        );
      }

      await _loadCurrentProfile(user.id);
    });
  }

  Future<void> signOut() async {
    _removeRealtimeChannels();
    if (!_isDemoMode) {
      await _client?.auth.signOut();
    }

    _currentRole = null;
    _customerProfile = null;
    _workerProfile = null;
    _needsProfileCompletion = false;
    _activeThreadId = null;
    _pendingAuthUser = null;
    _pendingNewUserRole = null;
    _errorMessage = null;
    _notifications.clear();
    notifyListeners();
  }

  Future<void> completeGoogleProfile({
    required AccountRole role,
    required String fullName,
    required String phone,
    required String city,
    String? serviceCategory,
    int? yearsExperience,
    String? nationalId,
    double? hourlyRate,
    String? bio,
  }) async {
    final user = _pendingAuthUser ?? _client?.auth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    await _runBusy(() async {
      _errorMessage = null;
      if (_isDemoMode) {
        if (role == AccountRole.worker) {
          _workerProfile = WorkerProfile(
            id: user.id,
            fullName: fullName,
            email: pendingEmail,
            phone: phone,
            city: city,
            serviceCategory: serviceCategory ?? 'Plumbing',
            yearsExperience: yearsExperience ?? 0,
            nationalId: nationalId ?? '',
            hourlyRate: hourlyRate ?? 0,
            bio: bio ?? '',
            isAvailable: true,
            avatarUrl: pendingAvatarUrl.isEmpty ? null : pendingAvatarUrl,
          );
          _currentRole = AccountRole.worker;
          _customerProfile = null;
        } else {
          _customerProfile = CustomerProfile(
            id: user.id,
            fullName: fullName,
            email: pendingEmail,
            phone: phone,
            city: city,
            avatarUrl: pendingAvatarUrl.isEmpty ? null : pendingAvatarUrl,
          );
          _currentRole = AccountRole.customer;
          _workerProfile = null;
        }
        _needsProfileCompletion = false;
        _pendingAuthUser = null;
        _pendingNewUserRole = null;
        return;
      }

      await _client!.from('profiles').upsert(<String, dynamic>{
        'id': user.id,
        'role': role.dbValue,
        'full_name': fullName,
        'email': user.email,
        'phone': phone,
        'city': city,
        'avatar_url': pendingAvatarUrl.isEmpty ? null : pendingAvatarUrl,
      });

      if (role == AccountRole.worker) {
        await _client!.from('worker_profiles').upsert(<String, dynamic>{
          'id': user.id,
          'service_category': serviceCategory ?? 'Plumbing',
          'years_experience': yearsExperience ?? 0,
          'national_id': nationalId ?? '',
          'hourly_rate': hourlyRate ?? 0,
          'bio': bio ?? '',
          'is_available': true,
        });
      }

      _needsProfileCompletion = false;
      _pendingNewUserRole = null;
      await _loadCurrentProfile(user.id, authUser: user);
    });
  }

  Future<void> createCustomerRequest({
    required String category,
    required String title,
    required String description,
    required String address,
    required DateTime scheduledFor,
    required double estimatedPrice,
    WorkerProfile? chosenWorker,
    Uint8List? attachmentBytes,
    String? attachmentName,
  }) async {
    if (_customerProfile == null) {
      return;
    }

    await _runBusy(() async {
      final threadId = 'thread-${DateTime.now().millisecondsSinceEpoch}';
      String? attachmentUrl;
      if (attachmentBytes != null && attachmentName != null) {
        attachmentUrl = await _uploadRequestAttachment(
          attachmentBytes,
          attachmentName,
        );
      }

      if (_isDemoMode) {
        final request = RequestJob(
          id: 'req-${DateTime.now().millisecondsSinceEpoch}',
          customerId: _customerProfile!.id,
          customerName: _customerProfile!.fullName,
          customerAddress: address,
          title: title,
          category: category,
          description: description,
          scheduledFor: scheduledFor,
          estimatedPrice: estimatedPrice,
          status: RequestStatus.pending,
          threadId: threadId,
          workerId: chosenWorker?.id,
          workerName: chosenWorker?.fullName,
          attachmentUrl: attachmentUrl,
        );

        _requests.insert(0, request);
        _threads.insert(
          0,
          MessageThread(
            id: threadId,
            requestId: request.id,
            customerName: _customerProfile!.fullName,
            workerName: chosenWorker?.fullName ?? 'FixIt Dispatch',
            lastMessage: chosenWorker == null
                ? 'New request created'
                : 'Waiting for ${chosenWorker.fullName} to confirm',
            lastMessageAt: DateTime.now(),
            unreadCount: 0,
            isOnline: true,
          ),
        );
        _messages[threadId] = <ChatMessage>[
          ChatMessage(
            id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
            threadId: threadId,
            senderId: _customerProfile!.id,
            receiverId: chosenWorker?.id ?? 'dispatch',
            body: description,
            createdAt: DateTime.now(),
          ),
        ];
        _prependNotification(
          AppNotification(
            id: 'notif-${DateTime.now().microsecondsSinceEpoch}',
            userId: _customerProfile!.id,
            title: 'Request submitted',
            body: chosenWorker == null
                ? 'Your request is now visible to available workers.'
                : 'Your request was sent to ${chosenWorker.fullName} and is waiting for confirmation.',
            createdAt: DateTime.now(),
            type: AppNotificationType.request,
            requestId: request.id,
            threadId: threadId,
          ),
        );
        if (chosenWorker != null) {
          _prependNotification(
            AppNotification(
              id: 'notif-worker-${DateTime.now().microsecondsSinceEpoch}',
              userId: chosenWorker.id,
              title: 'New assigned request',
              body: '${_customerProfile!.fullName} requested "$title".',
              createdAt: DateTime.now(),
              type: AppNotificationType.request,
              requestId: request.id,
              threadId: threadId,
            ),
          );
        }
        return;
      }

      final created = await _createRequestWithSupabase(
        category: category,
        title: title,
        description: description,
        address: address,
        scheduledFor: scheduledFor,
        estimatedPrice: estimatedPrice,
        chosenWorker: chosenWorker,
        attachmentUrl: attachmentUrl,
      );

      await _insertNotification(
        userId: _customerProfile!.id,
        title: 'Request submitted',
        body: chosenWorker == null
            ? 'Your request is now visible to available workers.'
            : 'Your request was sent to ${chosenWorker.fullName} and is waiting for confirmation.',
        type: AppNotificationType.request,
        requestId: created.requestId,
        threadId: created.threadId,
      );
      if (chosenWorker != null) {
        await _insertNotification(
          userId: chosenWorker.id,
          title: 'New assigned request',
          body: '${_customerProfile!.fullName} requested "$title".',
          type: AppNotificationType.request,
          requestId: created.requestId,
          threadId: created.threadId,
        );
      }

      await refreshData();
    });
  }

  Future<void> updateRequestStatus(
    RequestJob job,
    RequestStatus nextStatus,
  ) async {
    await _runBusy(() async {
      if (_isDemoMode) {
        final index = _requests.indexWhere((request) => request.id == job.id);
        if (index == -1) {
          return;
        }
        final updated = job.copyWith(
          status: nextStatus,
          workerId: _workerProfile?.id ?? job.workerId,
          workerName: _workerProfile?.fullName ?? job.workerName,
          completedAt: nextStatus == RequestStatus.completed
              ? DateTime.now()
              : job.completedAt,
        );
        _requests[index] = updated;

        final threadIndex = _threads.indexWhere(
          (thread) => thread.id == job.threadId,
        );
        if (threadIndex != -1 && _workerProfile != null) {
          _threads[threadIndex] = _threads[threadIndex].copyWith(
            workerName: _workerProfile!.fullName,
            lastMessage: _statusMessage(nextStatus),
            lastMessageAt: DateTime.now(),
          );
        }

        _prependNotification(
          AppNotification(
            id: 'notif-status-${DateTime.now().microsecondsSinceEpoch}',
            userId: job.customerId,
            title: 'Booking updated',
            body: _statusMessage(nextStatus),
            createdAt: DateTime.now(),
            type: AppNotificationType.request,
            requestId: job.id,
            threadId: job.threadId,
          ),
        );
        if (nextStatus == RequestStatus.completed && _workerProfile != null) {
          _prependNotification(
            AppNotification(
              id: 'notif-earning-${DateTime.now().microsecondsSinceEpoch}',
              userId: _workerProfile!.id,
              title: 'Job completed',
              body: 'You earned EGP ${job.estimatedPrice.toStringAsFixed(0)}.',
              createdAt: DateTime.now(),
              type: AppNotificationType.earning,
              requestId: job.id,
            ),
          );
        }
        return;
      }

      await _client!
          .from('service_requests')
          .update(<String, dynamic>{
            'status': _dbStatus(nextStatus),
            'worker_id': _workerProfile?.id ?? job.workerId,
            'worker_name': _workerProfile?.fullName ?? job.workerName,
            if (nextStatus == RequestStatus.completed)
              'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', job.id);

      await _client!
          .from('message_threads')
          .update(<String, dynamic>{
            'worker_name': _workerProfile?.fullName ?? job.workerName,
            'last_message': _statusMessage(nextStatus),
            'last_message_at': DateTime.now().toIso8601String(),
          })
          .eq('id', job.threadId);

      await _insertNotification(
        userId: job.customerId,
        title: 'Booking updated',
        body: _statusMessage(nextStatus),
        type: AppNotificationType.request,
        requestId: job.id,
        threadId: job.threadId,
      );
      if (nextStatus == RequestStatus.completed && _workerProfile != null) {
        await _insertNotification(
          userId: _workerProfile!.id,
          title: 'Job completed',
          body: 'You earned EGP ${job.estimatedPrice.toStringAsFixed(0)}.',
          type: AppNotificationType.earning,
          requestId: job.id,
        );
      }

      await refreshData();
    });
  }

  Future<void> sendMessage({
    required MessageThread thread,
    required String body,
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty ||
        _currentRole == null ||
        _sendingThreadIds.contains(thread.id)) {
      return;
    }

    final senderId = _currentRole == AccountRole.worker
        ? _workerProfile?.id ?? 'worker-demo'
        : _customerProfile?.id ?? 'customer-demo';
    final receiverId = _currentRole == AccountRole.worker
        ? _requestForThread(thread.id)?.customerId
        : _requestForThread(thread.id)?.workerId;

    _sendingThreadIds.add(thread.id);
    notifyListeners();

    await _runBusy(() async {
      if (_isDemoMode) {
        final list = _messages.putIfAbsent(thread.id, () => <ChatMessage>[]);
        list.add(
          ChatMessage(
            id: 'msg-${DateTime.now().microsecondsSinceEpoch}',
            threadId: thread.id,
            senderId: senderId,
            receiverId: receiverId ?? 'dispatch',
            body: trimmed,
            createdAt: DateTime.now(),
          ),
        );
        _replaceThread(
          thread.copyWith(
            lastMessage: trimmed,
            lastMessageAt: DateTime.now(),
            unreadCount: 0,
          ),
        );
        if (receiverId != null) {
          _prependNotification(
            AppNotification(
              id: 'notif-message-${DateTime.now().microsecondsSinceEpoch}',
              userId: receiverId,
              title: 'New message',
              body: trimmed,
              createdAt: DateTime.now(),
              type: AppNotificationType.message,
              threadId: thread.id,
              requestId: thread.requestId,
            ),
          );
        }
        return;
      }

      try {
        final response = await _client!.functions.invoke(
          'send-chat-message',
          body: <String, dynamic>{'thread_id': thread.id, 'body': trimmed},
        );
        if (response.status >= 400) {
          throw Exception('Chat send failed.');
        }
      } catch (_) {
        await _client!.from('messages').insert(<String, dynamic>{
          'thread_id': thread.id,
          'sender_id': senderId,
          'receiver_id': receiverId,
          'body': trimmed,
        });

        await _client!
            .from('message_threads')
            .update(<String, dynamic>{
              'last_message': trimmed,
              'last_message_at': DateTime.now().toIso8601String(),
              'unread_count': 0,
            })
            .eq('id', thread.id);

        if (receiverId != null) {
          await _insertNotification(
            userId: receiverId,
            title: 'New message',
            body: trimmed,
            type: AppNotificationType.message,
            requestId: thread.requestId,
            threadId: thread.id,
          );
        }
      }

      await _loadMessages(thread.id, silentNotify: true);
      await refreshData();
    });

    _sendingThreadIds.remove(thread.id);
    notifyListeners();
  }

  Future<void> openThread(String threadId) async {
    _activeThreadId = threadId;
    if (_isDemoMode) {
      notifyListeners();
      return;
    }

    _configureActiveThreadRealtime(threadId);
    await _loadMessages(threadId, silentNotify: true);
    notifyListeners();
  }

  void closeThread(String threadId) {
    if (_activeThreadId != threadId) {
      return;
    }
    _activeThreadId = null;
    _removeActiveThreadChannel();
  }

  Future<void> refreshData() async {
    if (_isDemoMode || _currentRole == null) {
      notifyListeners();
      return;
    }

    await _runBusy(() async {
      final requestsRows = await _client!
          .from('service_requests')
          .select()
          .order('scheduled_for');
      final threadRows = await _client!
          .from('message_threads')
          .select()
          .order('last_message_at');
      final workerRows = await _client!
          .from('worker_profiles')
          .select(
            'id, service_category, years_experience, national_id, hourly_rate, bio, is_available, rating, completed_jobs, profiles!inner(id, full_name, email, phone, city, avatar_url)',
          )
          .eq('is_available', true);
      final userId = _currentRole == AccountRole.worker
          ? _workerProfile!.id
          : _customerProfile!.id;
      final notificationRows = await _client!
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at');

      _requests
        ..clear()
        ..addAll(
          requestsRows
              .map<RequestJob>(
                (dynamic row) => _requestFromMap(row as Map<String, dynamic>),
              )
              .toList(),
        );
      _threads
        ..clear()
        ..addAll(
          threadRows
              .map<MessageThread>(
                (dynamic row) => _threadFromMap(row as Map<String, dynamic>),
              )
              .toList(),
        );
      _availableWorkers
        ..clear()
        ..addAll(
          workerRows
              .map<WorkerProfile>(
                (dynamic row) => _workerFromJoin(row as Map<String, dynamic>),
              )
              .toList(),
        );
      _notifications
        ..clear()
        ..addAll(
          notificationRows
              .map<AppNotification>(
                (dynamic row) =>
                    _notificationFromMap(row as Map<String, dynamic>),
              )
              .toList(),
        );

      if (_activeThreadId != null) {
        await _loadMessages(_activeThreadId!, silentNotify: true);
      }
    }, silentNotify: true);

    notifyListeners();
  }

  Future<void> toggleAvailability(bool value) async {
    if (_workerProfile == null) {
      return;
    }

    _workerProfile = _workerProfile!.copyWith(isAvailable: value);
    notifyListeners();

    if (_isDemoMode) {
      return;
    }

    await _client!
        .from('worker_profiles')
        .update(<String, dynamic>{'is_available': value})
        .eq('id', _workerProfile!.id);

    await refreshData();
  }

  Future<void> updateCurrentProfile({
    required String fullName,
    required String phone,
    required String city,
    String? serviceCategory,
    int? yearsExperience,
    String? nationalId,
    double? hourlyRate,
    String? bio,
  }) async {
    if (_currentRole == null) {
      return;
    }

    await _runBusy(() async {
      if (_currentRole == AccountRole.customer && _customerProfile != null) {
        _customerProfile = _customerProfile!.copyWith(
          fullName: fullName,
          phone: phone,
          city: city,
        );

        if (_isDemoMode) {
          return;
        }

        await _client!
            .from('profiles')
            .update(<String, dynamic>{
              'full_name': fullName,
              'phone': phone,
              'city': city,
            })
            .eq('id', _customerProfile!.id);
        return;
      }

      if (_currentRole == AccountRole.worker && _workerProfile != null) {
        _workerProfile = _workerProfile!.copyWith(
          fullName: fullName,
          phone: phone,
          city: city,
          serviceCategory: serviceCategory,
          yearsExperience: yearsExperience,
          nationalId: nationalId,
          hourlyRate: hourlyRate,
          bio: bio,
        );

        if (_isDemoMode) {
          return;
        }

        await _client!
            .from('profiles')
            .update(<String, dynamic>{
              'full_name': fullName,
              'phone': phone,
              'city': city,
            })
            .eq('id', _workerProfile!.id);

        await _client!
            .from('worker_profiles')
            .update(<String, dynamic>{
              'service_category':
                  serviceCategory ?? _workerProfile!.serviceCategory,
              'years_experience':
                  yearsExperience ?? _workerProfile!.yearsExperience,
              'national_id': nationalId ?? _workerProfile!.nationalId,
              'hourly_rate': hourlyRate ?? _workerProfile!.hourlyRate,
              'bio': bio ?? _workerProfile!.bio,
            })
            .eq('id', _workerProfile!.id);
      }
    });
  }

  Future<bool> submitSupportTicket({
    required String type,
    required String subject,
    required String message,
  }) async {
    if (_currentRole == null) {
      return false;
    }

    final currentUserId = _currentRole == AccountRole.worker
        ? _workerProfile?.id
        : _customerProfile?.id;
    if (currentUserId == null) {
      return false;
    }

    var submitted = false;
    await _runBusy(() async {
      if (_isDemoMode) {
        _prependNotification(
          AppNotification(
            id: 'support-${DateTime.now().microsecondsSinceEpoch}',
            userId: currentUserId,
            title: type == 'bug' ? 'Bug report sent' : 'Support ticket opened',
            body: subject,
            createdAt: DateTime.now(),
            type: AppNotificationType.system,
          ),
        );
        submitted = true;
        return;
      }

      await _client!.from('support_tickets').insert(<String, dynamic>{
        'user_id': currentUserId,
        'role': _currentRole!.dbValue,
        'type': type,
        'subject': subject,
        'message': message,
      });
      submitted = true;
    });
    return submitted;
  }

  Future<void> markNotificationsRead() async {
    if (_notifications.isEmpty) {
      return;
    }
    for (var i = 0; i < _notifications.length; i += 1) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();

    if (_isDemoMode || _currentRole == null) {
      return;
    }

    final userId = _currentRole == AccountRole.worker
        ? _workerProfile!.id
        : _customerProfile!.id;
    await _client!
        .from('notifications')
        .update(<String, dynamic>{'is_read': true})
        .eq('user_id', userId);
  }

  Future<void> uploadCurrentUserAvatar(Uint8List bytes, String fileName) async {
    if (_currentRole == null) {
      return;
    }
    await _runBusy(() async {
      final publicUrl = await _uploadAvatar(bytes, fileName);
      if (_currentRole == AccountRole.customer && _customerProfile != null) {
        _customerProfile = _customerProfile!.copyWith(avatarUrl: publicUrl);
      } else if (_currentRole == AccountRole.worker && _workerProfile != null) {
        _workerProfile = _workerProfile!.copyWith(avatarUrl: publicUrl);
      }

      if (_isDemoMode) {
        return;
      }
      final userId = _currentRole == AccountRole.worker
          ? _workerProfile!.id
          : _customerProfile!.id;
      await _client!
          .from('profiles')
          .update(<String, dynamic>{'avatar_url': publicUrl})
          .eq('id', userId);
    });
  }

  RequestJob? requestById(String id) {
    for (final request in _requests) {
      if (request.id == id) {
        return request;
      }
    }
    return null;
  }

  RequestJob? _requestForThread(String threadId) {
    for (final request in _requests) {
      if (request.threadId == threadId) {
        return request;
      }
    }
    return null;
  }

  Future<void> _loadCurrentProfile(String userId, {User? authUser}) async {
    _pendingAuthUser = authUser ?? _client?.auth.currentUser;
    final profile = await _client!
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (profile == null) {
      _needsProfileCompletion = true;
      _currentRole = null;
      notifyListeners();
      return;
    }
    final role = AccountRoleX.fromDb(profile['role'] as String? ?? 'customer');
    final isBaseProfileIncomplete =
        (profile['full_name'] as String? ?? '').trim().isEmpty ||
        (profile['phone'] as String? ?? '').trim().isEmpty ||
        (profile['city'] as String? ?? '').trim().isEmpty;
    final shouldPreferSelectedRole =
        _pendingNewUserRole != null && isBaseProfileIncomplete;
    final resolvedRole = shouldPreferSelectedRole ? _pendingNewUserRole! : role;

    _currentRole = resolvedRole;

    if (resolvedRole == AccountRole.customer) {
      if (isBaseProfileIncomplete) {
        _needsProfileCompletion = true;
        notifyListeners();
        return;
      }
      _customerProfile = CustomerProfile(
        id: userId,
        fullName: profile['full_name'] as String? ?? 'Customer',
        email: profile['email'] as String? ?? '',
        phone: profile['phone'] as String? ?? '',
        city: profile['city'] as String? ?? '',
        avatarUrl: profile['avatar_url'] as String?,
      );
      _workerProfile = null;
    } else {
      final worker = await _client!
          .from('worker_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      final workerIncomplete =
          worker == null ||
          (worker['service_category'] as String? ?? '').trim().isEmpty ||
          (worker['national_id'] as String? ?? '').trim().isEmpty ||
          (worker['bio'] as String? ?? '').trim().isEmpty;
      if (isBaseProfileIncomplete || workerIncomplete) {
        _needsProfileCompletion = true;
        _customerProfile = null;
        _workerProfile = null;
        notifyListeners();
        return;
      }
      _workerProfile = WorkerProfile(
        id: userId,
        fullName: profile['full_name'] as String? ?? 'Worker',
        email: profile['email'] as String? ?? '',
        phone: profile['phone'] as String? ?? '',
        city: profile['city'] as String? ?? '',
        serviceCategory: worker['service_category'] as String? ?? 'General',
        yearsExperience: (worker['years_experience'] as num?)?.toInt() ?? 0,
        nationalId: worker['national_id'] as String? ?? '',
        hourlyRate: (worker['hourly_rate'] as num?)?.toDouble() ?? 0,
        bio: worker['bio'] as String? ?? '',
        isAvailable: worker['is_available'] as bool? ?? true,
        rating: (worker['rating'] as num?)?.toDouble() ?? 4.7,
        completedJobs: (worker['completed_jobs'] as num?)?.toInt() ?? 0,
        isVerified: worker['is_verified'] as bool? ?? true,
        avatarUrl: profile['avatar_url'] as String?,
      );
      _customerProfile = null;
    }

    _needsProfileCompletion = false;
    _pendingNewUserRole = null;
    await refreshData();
    _configureRealtime();
  }

  Future<String?> _uploadRequestAttachment(
    Uint8List bytes,
    String fileName,
  ) async {
    if (_isDemoMode) {
      return null;
    }
    final objectPath =
        'requests/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    await _client!.storage
        .from('request-images')
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client!.storage.from('request-images').getPublicUrl(objectPath);
  }

  Future<String?> _uploadAvatar(Uint8List bytes, String fileName) async {
    if (_isDemoMode) {
      return null;
    }
    final userId = _currentRole == AccountRole.worker
        ? _workerProfile!.id
        : _customerProfile!.id;
    final objectPath = 'avatars/$userId/$fileName';
    await _client!.storage
        .from('avatars')
        .uploadBinary(
          objectPath,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return _client!.storage.from('avatars').getPublicUrl(objectPath);
  }

  Future<({String requestId, String threadId})> _createRequestWithSupabase({
    required String category,
    required String title,
    required String description,
    required String address,
    required DateTime scheduledFor,
    required double estimatedPrice,
    WorkerProfile? chosenWorker,
    String? attachmentUrl,
  }) async {
    final inserted = await _client!
        .from('service_requests')
        .insert(<String, dynamic>{
          'customer_id': _customerProfile!.id,
          'customer_name': _customerProfile!.fullName,
          'worker_id': chosenWorker?.id,
          'worker_name': chosenWorker?.fullName,
          'category': category,
          'title': title,
          'description': description,
          'address': address,
          'scheduled_for': scheduledFor.toIso8601String(),
          'price': estimatedPrice,
          'status': 'pending',
          'attachment_url': attachmentUrl,
        })
        .select()
        .single();

    final thread = await _client!
        .from('message_threads')
        .insert(<String, dynamic>{
          'request_id': inserted['id'],
          'customer_name': _customerProfile!.fullName,
          'worker_name': chosenWorker?.fullName ?? 'FixIt Dispatch',
          'last_message': chosenWorker == null
              ? 'New request created'
              : 'Waiting for worker confirmation',
          'last_message_at': DateTime.now().toIso8601String(),
          'unread_count': 0,
        })
        .select()
        .single();

    final threadId = thread['id'] as String;

    await _client!
        .from('service_requests')
        .update(<String, dynamic>{'thread_id': threadId})
        .eq('id', inserted['id']);

    await _client!.from('messages').insert(<String, dynamic>{
      'thread_id': threadId,
      'sender_id': _customerProfile!.id,
      'receiver_id': chosenWorker?.id,
      'body': description,
    });

    return (requestId: inserted['id'] as String, threadId: threadId);
  }

  Future<void> _insertNotification({
    required String userId,
    required String title,
    required String body,
    required AppNotificationType type,
    String? requestId,
    String? threadId,
  }) async {
    if (_isDemoMode) {
      return;
    }
    await _client!.from('notifications').insert(<String, dynamic>{
      'user_id': userId,
      'title': title,
      'body': body,
      'type': _notificationTypeValue(type),
      'request_id': requestId,
      'thread_id': threadId,
      'is_read': false,
    });
  }

  Future<void> _loadMessages(
    String threadId, {
    bool silentNotify = false,
  }) async {
    if (_isDemoMode || _client == null) {
      return;
    }

    final rows = await _client!
        .from('messages')
        .select()
        .eq('thread_id', threadId)
        .order('created_at');
    _messages[threadId] = rows
        .map<ChatMessage>(
          (dynamic row) => _chatMessageFromMap(row as Map<String, dynamic>),
        )
        .toList();
    if (!silentNotify) {
      notifyListeners();
    }
  }

  Future<void> _runBusy(
    Future<void> Function() action, {
    bool silentNotify = false,
  }) async {
    _errorMessage = null;
    _isBusy = true;
    if (!silentNotify) {
      notifyListeners();
    }
    try {
      await action();
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _seedDemoCollections() {
    _requests
      ..clear()
      ..addAll(DemoData.requests.map((job) => job.copyWith()).toList());
    _threads
      ..clear()
      ..addAll(DemoData.threads.map((thread) => thread.copyWith()).toList());
    _availableWorkers
      ..clear()
      ..addAll(DemoData.workers);
    _messages
      ..clear()
      ..addAll(
        DemoData.messages.map(
          (key, value) => MapEntry<String, List<ChatMessage>>(
            key,
            value
                .map(
                  (message) => ChatMessage(
                    id: message.id,
                    threadId: message.threadId,
                    senderId: message.senderId,
                    receiverId: message.receiverId,
                    body: message.body,
                    createdAt: message.createdAt,
                  ),
                )
                .toList(),
          ),
        ),
      );
  }

  void _replaceThread(MessageThread thread) {
    final index = _threads.indexWhere((item) => item.id == thread.id);
    if (index == -1) {
      _threads.insert(0, thread);
      return;
    }
    _threads[index] = thread;
  }

  void _prependNotification(AppNotification notification) {
    final currentUserId = _currentRole == AccountRole.worker
        ? _workerProfile?.id
        : _customerProfile?.id;
    if (currentUserId == null || notification.userId == currentUserId) {
      _notifications.insert(0, notification);
    }
  }

  void _configureRealtime() {
    if (_isDemoMode || _client == null || _currentRole == null) {
      return;
    }
    _removeRealtimeChannels();
    final channel =
        _client!.channel('fixit-sync-${DateTime.now().millisecondsSinceEpoch}')
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'service_requests',
            callback: (_) => unawaited(refreshData()),
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'message_threads',
            callback: (_) => unawaited(refreshData()),
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'messages',
            callback: (_) => unawaited(refreshData()),
          )
          ..onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'notifications',
            callback: (_) => unawaited(refreshData()),
          )
          ..subscribe();
    _channels.add(channel);
  }

  void _configureActiveThreadRealtime(String threadId) {
    if (_isDemoMode || _client == null) {
      return;
    }

    _removeActiveThreadChannel();
    _activeThreadChannel = _client!.channel('fixit-thread-$threadId')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'thread_id',
          value: threadId,
        ),
        callback: (_) => unawaited(_loadMessages(threadId)),
      )
      ..subscribe();
  }

  void _removeRealtimeChannels() {
    if (_client == null) {
      _channels.clear();
      _activeThreadChannel = null;
      return;
    }
    for (final channel in _channels) {
      _client!.removeChannel(channel);
    }
    _channels.clear();
    _removeActiveThreadChannel();
  }

  void _removeActiveThreadChannel() {
    if (_client != null && _activeThreadChannel != null) {
      _client!.removeChannel(_activeThreadChannel!);
    }
    _activeThreadChannel = null;
  }

  String _statusMessage(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'Waiting for a worker';
      case RequestStatus.accepted:
        return 'Request accepted';
      case RequestStatus.inProgress:
        return 'Work started';
      case RequestStatus.completed:
        return 'Request completed';
      case RequestStatus.cancelled:
        return 'Request cancelled';
    }
  }

  String _dbStatus(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return 'pending';
      case RequestStatus.accepted:
        return 'accepted';
      case RequestStatus.inProgress:
        return 'in_progress';
      case RequestStatus.completed:
        return 'completed';
      case RequestStatus.cancelled:
        return 'cancelled';
    }
  }

  String _notificationTypeValue(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.request:
        return 'request';
      case AppNotificationType.message:
        return 'message';
      case AppNotificationType.earning:
        return 'earning';
      case AppNotificationType.system:
        return 'system';
    }
  }

  AppNotificationType _notificationTypeFromDb(String value) {
    switch (value) {
      case 'message':
        return AppNotificationType.message;
      case 'earning':
        return AppNotificationType.earning;
      case 'system':
        return AppNotificationType.system;
      default:
        return AppNotificationType.request;
    }
  }

  RequestJob _requestFromMap(Map<String, dynamic> map) {
    return RequestJob(
      id: map['id'] as String,
      customerId: map['customer_id'] as String? ?? '',
      customerName: map['customer_name'] as String? ?? 'Customer',
      customerAddress: map['address'] as String? ?? '',
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? '',
      description: map['description'] as String? ?? '',
      scheduledFor:
          DateTime.tryParse(map['scheduled_for'] as String? ?? '') ??
          DateTime.now(),
      estimatedPrice: (map['price'] as num?)?.toDouble() ?? 0,
      status: _requestStatusFromDb(map['status'] as String? ?? 'pending'),
      threadId: map['thread_id'] as String? ?? '',
      workerName: map['worker_name'] as String?,
      workerId: map['worker_id'] as String?,
      attachmentUrl: map['attachment_url'] as String?,
      completedAt: DateTime.tryParse(map['completed_at'] as String? ?? ''),
    );
  }

  DateTime _earningsDateFor(RequestJob job) {
    return job.completedAt ?? job.scheduledFor;
  }

  WorkerProfile _workerFromJoin(Map<String, dynamic> map) {
    final profile =
        map['profiles'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return WorkerProfile(
      id: map['id'] as String,
      fullName: profile['full_name'] as String? ?? 'Worker',
      email: profile['email'] as String? ?? '',
      phone: profile['phone'] as String? ?? '',
      city: profile['city'] as String? ?? '',
      serviceCategory: map['service_category'] as String? ?? 'General',
      yearsExperience: (map['years_experience'] as num?)?.toInt() ?? 0,
      nationalId: map['national_id'] as String? ?? '',
      hourlyRate: (map['hourly_rate'] as num?)?.toDouble() ?? 0,
      bio: map['bio'] as String? ?? '',
      isAvailable: map['is_available'] as bool? ?? true,
      rating: (map['rating'] as num?)?.toDouble() ?? 4.7,
      completedJobs: (map['completed_jobs'] as num?)?.toInt() ?? 0,
      isVerified: map['is_verified'] as bool? ?? true,
      avatarUrl: profile['avatar_url'] as String?,
    );
  }

  MessageThread _threadFromMap(Map<String, dynamic> map) {
    return MessageThread(
      id: map['id'] as String,
      requestId: map['request_id'] as String? ?? '',
      customerName: map['customer_name'] as String? ?? 'Customer',
      workerName: map['worker_name'] as String? ?? 'FixIt Dispatch',
      lastMessage: map['last_message'] as String? ?? '',
      lastMessageAt:
          DateTime.tryParse(map['last_message_at'] as String? ?? '') ??
          DateTime.now(),
      unreadCount: (map['unread_count'] as num?)?.toInt() ?? 0,
      isOnline: map['is_online'] as bool? ?? false,
    );
  }

  AppNotification _notificationFromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      type: _notificationTypeFromDb(map['type'] as String? ?? 'request'),
      isRead: map['is_read'] as bool? ?? false,
      requestId: map['request_id'] as String?,
      threadId: map['thread_id'] as String?,
    );
  }

  ChatMessage _chatMessageFromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      threadId: map['thread_id'] as String? ?? '',
      senderId: map['sender_id'] as String? ?? '',
      receiverId: map['receiver_id'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  RequestStatus _requestStatusFromDb(String value) {
    switch (value) {
      case 'accepted':
        return RequestStatus.accepted;
      case 'in_progress':
        return RequestStatus.inProgress;
      case 'completed':
        return RequestStatus.completed;
      case 'cancelled':
        return RequestStatus.cancelled;
      default:
        return RequestStatus.pending;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _removeRealtimeChannels();
    super.dispose();
  }
}
