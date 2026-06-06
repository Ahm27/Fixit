import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/request_job.dart';
import '../../services/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_chip.dart';
import 'chat_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';
import 'request_details_page.dart';

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({super.key});

  @override
  State<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final text = app.strings;
    final worker = app.workerProfile;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 88,
        title: Row(
          children: [
            if (worker?.avatarUrl != null)
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(worker!.avatarUrl!),
              )
            else
              AvatarBadge(initials: worker?.initials ?? 'WK'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker?.fullName ?? text.workerFallback,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    worker == null
                        ? text.general
                        : text.serviceCategoryName(worker.serviceCategory),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
          if (worker != null)
            Switch(
              value: worker.isAvailable,
              onChanged: app.toggleAvailability,
              activeThumbColor: AppColors.primary,
            ),
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const NotificationsPage(isWorkerView: true),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              if (app.unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      app.unreadNotificationCount > 9
                          ? '9+'
                          : '${app.unreadNotificationCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: app.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _index,
          children: const [
            _WorkerRequestsTab(),
            _WorkerEarningsTab(),
            _WorkerMessagesTab(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment_rounded),
            label: text.requests,
          ),
          NavigationDestination(
            icon: const Icon(Icons.payments_outlined),
            selectedIcon: const Icon(Icons.payments_rounded),
            label: text.earnings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.forum_outlined),
            selectedIcon: const Icon(Icons.forum_rounded),
            label: text.messages,
          ),
        ],
      ),
    );
  }
}

class _WorkerRequestsTab extends StatefulWidget {
  const _WorkerRequestsTab();

  @override
  State<_WorkerRequestsTab> createState() => _WorkerRequestsTabState();
}

class _WorkerRequestsTabState extends State<_WorkerRequestsTab> {
  RequestBucket _bucket = RequestBucket.newJobs;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final currentWorkerId = app.workerProfile?.id;
    final requests = app.workerRequests.where((job) {
      switch (_bucket) {
        case RequestBucket.newJobs:
          return job.status == RequestStatus.pending && job.workerId == null;
        case RequestBucket.active:
          return job.status == RequestStatus.accepted ||
              job.status == RequestStatus.inProgress ||
              (job.status == RequestStatus.pending &&
                  job.workerId != null &&
                  job.workerId == currentWorkerId);
        case RequestBucket.done:
          return job.status == RequestStatus.completed;
      }
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                app.strings.requests,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: app.refreshData,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: app.strings.refresh,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                app.strings.workerControlRoom,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                app.strings.workerControlRoomSubtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.82),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: RequestBucket.values.map((bucket) {
            final active = bucket == _bucket;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: bucket == RequestBucket.newJobs ? 8 : 0,
                  left: bucket == RequestBucket.done ? 8 : 4,
                ),
                child: InkWell(
                  onTap: () => setState(() => _bucket = bucket),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: active ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      app.strings.requestBucketLabel(bucket.key),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: active ? Colors.white : AppColors.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        if (requests.isEmpty)
          GlassCard(
            child: Text(
              app.strings.noRequestsSection,
              style: const TextStyle(color: AppColors.muted),
            ),
          )
        else
          ...requests.map(
            (job) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _WorkerRequestCard(job: job),
            ),
          ),
      ],
    );
  }
}

class _WorkerRequestCard extends StatelessWidget {
  const _WorkerRequestCard({required this.job});

  final RequestJob job;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppController>();
    final text = context.watch<AppController>().strings;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                RequestDetailsPage(jobId: job.id, isWorkerView: true),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    job.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                StatusChip(status: job.status),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                AvatarBadge(initials: _initials(job.customerName), size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        job.customerAddress,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              job.description,
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
            if (job.attachmentUrl != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  job.attachmentUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 90,
                    color: const Color(0xFFE8F5F1),
                    alignment: Alignment.center,
                    child: Text(text.customerAttachmentAdded),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  DateFormat('EEE, MMM d - h:mm a').format(job.scheduledFor),
                  style: const TextStyle(color: AppColors.muted),
                ),
                const Spacer(),
                Text(
                  text.currency(job.estimatedPrice),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    label: _actionLabel(job.status, text),
                    onPressed:
                        job.status == RequestStatus.completed ||
                            job.status == RequestStatus.cancelled
                        ? null
                        : () async {
                            await app.updateRequestStatus(
                              job,
                              _nextStatus(job.status),
                            );
                          },
                  ),
                ),
                const SizedBox(width: 10),
                PrimaryButton(
                  label: text.chat,
                  expanded: false,
                  variant: PrimaryButtonVariant.outline,
                  onPressed: () {
                    final thread = app.visibleThreads.firstWhere(
                      (item) => item.id == job.threadId,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ChatPage(thread: thread, isWorkerView: true),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _actionLabel(RequestStatus status, AppStrings text) {
    switch (status) {
      case RequestStatus.pending:
        return text.acceptJob;
      case RequestStatus.accepted:
        return text.startWork;
      case RequestStatus.inProgress:
        return text.markComplete;
      case RequestStatus.completed:
        return text.completed;
      case RequestStatus.cancelled:
        return text.cancelled;
    }
  }

  static RequestStatus _nextStatus(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return RequestStatus.accepted;
      case RequestStatus.accepted:
        return RequestStatus.inProgress;
      case RequestStatus.inProgress:
        return RequestStatus.completed;
      case RequestStatus.completed:
        return RequestStatus.completed;
      case RequestStatus.cancelled:
        return RequestStatus.cancelled;
    }
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'CU';
    }
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }
}

class _WorkerEarningsTab extends StatelessWidget {
  const _WorkerEarningsTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final text = app.strings;
    final earnings = app.earningsSummary;
    final completed =
        app.workerRequests
            .where((job) => job.status == RequestStatus.completed)
            .toList()
          ..sort(
            (a, b) => (b.completedAt ?? b.scheduledFor).compareTo(
              a.completedAt ?? a.scheduledFor,
            ),
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          text.earnings,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _MetricCard(label: text.today, value: earnings.today),
            _MetricCard(label: text.thisWeek, value: earnings.thisWeek),
            _MetricCard(label: text.thisMonth, value: earnings.thisMonth),
            _MetricCard(
              label: text.availableBalance,
              value: earnings.availableBalance,
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassCard(
          color: const Color(0xFFE8F5F1),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.performance,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      text.performanceSummary(
                        earnings.completedJobs,
                        earnings.averageTicket,
                      ),
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.trending_up_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          text.completedJobsTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (completed.isEmpty)
          GlassCard(
            child: Text(
              text.completedJobsHint,
              style: const TextStyle(color: AppColors.muted),
            ),
          )
        else
          ...completed.map(
            (job) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.customerName,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          text.currency(job.estimatedPrice),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'MMM d',
                          ).format(job.completedAt ?? job.scheduledFor),
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final text = context.watch<AppController>().strings;
    final width = (MediaQuery.of(context).size.width - 52) / 2;
    return SizedBox(
      width: width,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 8),
            Text(
              text.currency(value),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkerMessagesTab extends StatelessWidget {
  const _WorkerMessagesTab();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final text = app.strings;
    final threads = app.visibleThreads;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                text.messages,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            IconButton(
              onPressed: app.refreshData,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: text.refresh,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (threads.isEmpty)
          GlassCard(
            child: Text(
              text.noConversationsYet,
              style: const TextStyle(color: AppColors.muted),
            ),
          )
        else
          ...List.generate(threads.length, (index) {
            final thread = threads[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == threads.length - 1 ? 0 : 12,
              ),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ChatPage(thread: thread, isWorkerView: true),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(22),
                child: GlassCard(
                  child: Row(
                    children: [
                      AvatarBadge(initials: thread.initialsFor(true)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              thread.counterpartFor(true),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              thread.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      if (thread.unreadCount > 0)
                        Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${thread.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}

enum RequestBucket { newJobs, active, done }

extension on RequestBucket {
  String get key {
    switch (this) {
      case RequestBucket.newJobs:
        return 'new';
      case RequestBucket.active:
        return 'active';
      case RequestBucket.done:
        return 'done';
    }
  }
}
