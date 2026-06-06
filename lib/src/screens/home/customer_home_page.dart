import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/request_job.dart';
import '../../services/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_chip.dart';
import 'booking_flow_page.dart';
import 'chat_page.dart';
import 'notifications_page.dart';
import 'profile_page.dart';
import 'request_details_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final text = controller.strings;
    final profile = controller.customerProfile;
    final pages = [
      _CustomerDashboardTab(onBookCategory: _openBookingFlow),
      const _CustomerBookingsTab(),
      const _CustomerMessagesTab(),
      const _CustomerProfileTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 82,
        title: Row(
          children: [
            if (profile?.avatarUrl != null)
              CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(profile!.avatarUrl!),
              )
            else
              AvatarBadge(initials: profile?.initials ?? 'CU'),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.appName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  text.helloFirstName(profile?.fullName),
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: controller.refreshData,
            icon: const Icon(Icons.refresh_rounded),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          const NotificationsPage(isWorkerView: false),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              if (controller.unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: _NotificationDot(
                    count: controller.unreadNotificationCount,
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: controller.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: IndexedStack(index: _currentIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (value) => setState(() => _currentIndex = value),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: text.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: text.bookings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: const Icon(Icons.chat_bubble_rounded),
            label: text.messages,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: text.profile,
          ),
        ],
      ),
    );
  }

  Future<void> _openBookingFlow(String category) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingFlowPage(initialCategory: category),
      ),
    );
  }
}

class _CustomerDashboardTab extends StatelessWidget {
  const _CustomerDashboardTab({required this.onBookCategory});

  final Future<void> Function(String category) onBookCategory;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final text = controller.strings;
    final recent = controller.customerRequests.take(2).toList();
    final firstCategory = controller.serviceCategories.isEmpty
        ? null
        : controller.serviceCategories.first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFE8F5F1)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.whatServiceNeed,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                text.homeHeroSubtitle,
                style: const TextStyle(color: AppColors.muted, height: 1.35),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: text.startBooking,
                onPressed: firstCategory == null
                    ? null
                    : () {
                        onBookCategory(firstCategory);
                      },
                expanded: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          text.serviceCategoriesTitle,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ...controller.serviceCategories.map((category) {
          final isAvailable = controller.hasAvailableWorkersForCategory(
            category,
          );
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Opacity(
              opacity: isAvailable ? 1 : 0.45,
              child: InkWell(
                onTap: () => onBookCategory(category),
                borderRadius: BorderRadius.circular(24),
                child: GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _serviceColor(
                            category,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _serviceIcon(category),
                          color: _serviceColor(category),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              text.serviceCategoryName(category),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAvailable
                                  ? text.serviceDescription(category)
                                  : text.noAvailableWorkersAtMoment,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isAvailable ? AppColors.text : AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        Text(
          text.recentBookings,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        if (recent.isEmpty)
          GlassCard(
            child: Text(
              text.firstBookingHint,
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
          )
        else
          ...recent.map(
            (job) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BookingCard(job: job),
            ),
          ),
      ],
    );
  }

  static Color _serviceColor(String category) {
    switch (category) {
      case 'Plumbing':
        return AppColors.primary;
      case 'Electrical':
        return const Color(0xFFF2A541);
      case 'Painting':
        return const Color(0xFF8E6CC8);
      case 'Carpentry':
        return const Color(0xFF996633);
      case 'AC Repair':
        return const Color(0xFF468CD8);
      default:
        return const Color(0xFF465A64);
    }
  }

  static IconData _serviceIcon(String category) {
    switch (category) {
      case 'Plumbing':
        return Icons.water_drop_outlined;
      case 'Electrical':
        return Icons.flash_on_rounded;
      case 'Painting':
        return Icons.format_paint_rounded;
      case 'Carpentry':
        return Icons.handyman_rounded;
      case 'AC Repair':
        return Icons.ac_unit_rounded;
      default:
        return Icons.home_repair_service_rounded;
    }
  }
}

class _CustomerBookingsTab extends StatefulWidget {
  const _CustomerBookingsTab();

  @override
  State<_CustomerBookingsTab> createState() => _CustomerBookingsTabState();
}

class _CustomerBookingsTabState extends State<_CustomerBookingsTab> {
  bool _showActive = true;

  @override
  Widget build(BuildContext context) {
    final requests = context.watch<AppController>().customerRequests;
    final text = context.watch<AppController>().strings;
    final filtered = requests.where((job) {
      final active =
          job.status == RequestStatus.pending ||
          job.status == RequestStatus.accepted ||
          job.status == RequestStatus.inProgress;
      return _showActive ? active : !active;
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            _toggle(
              text.active,
              _showActive,
              () => setState(() => _showActive = true),
            ),
            const SizedBox(width: 8),
            _toggle(
              text.history,
              !_showActive,
              () => setState(() => _showActive = false),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (filtered.isEmpty)
          GlassCard(
            child: Text(
              text.noBookingsSection,
              style: const TextStyle(color: AppColors.muted),
            ),
          )
        else
          ...filtered.map(
            (job) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _BookingCard(job: job),
            ),
          ),
      ],
    );
  }

  Widget _toggle(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
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
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: active ? Colors.white : AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomerMessagesTab extends StatelessWidget {
  const _CustomerMessagesTab();

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
                          ChatPage(thread: thread, isWorkerView: false),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(22),
                child: GlassCard(
                  child: Row(
                    children: [
                      AvatarBadge(initials: thread.initialsFor(false)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              thread.counterpartFor(false),
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
                      const Icon(Icons.chevron_right_rounded),
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

class _CustomerProfileTab extends StatefulWidget {
  const _CustomerProfileTab();

  @override
  State<_CustomerProfileTab> createState() => _CustomerProfileTabState();
}

class _CustomerProfileTabState extends State<_CustomerProfileTab> {
  @override
  Widget build(BuildContext context) {
    return const ProfilePage(embedded: true);
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.job});

  final RequestJob job;

  @override
  Widget build(BuildContext context) {
    final text = context.watch<AppController>().strings;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                RequestDetailsPage(jobId: job.id, isWorkerView: false),
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
                      fontSize: 17,
                    ),
                  ),
                ),
                StatusChip(status: job.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              job.description,
              style: const TextStyle(color: AppColors.muted, height: 1.35),
            ),
            if (job.workerName != null) ...[
              const SizedBox(height: 10),
              Text(
                text.assignedTo(job.workerName!),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    job.customerAddress,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 18,
                  color: AppColors.muted,
                ),
                const SizedBox(width: 6),
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
            if (job.attachmentUrl != null) ...[
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  job.attachmentUrl!,
                  height: 124,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 124,
                    color: const Color(0xFFE8F5F1),
                    alignment: Alignment.center,
                    child: Text(text.attachmentAdded),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationDot extends StatelessWidget {
  const _NotificationDot({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: const BoxDecoration(
        color: AppColors.danger,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
