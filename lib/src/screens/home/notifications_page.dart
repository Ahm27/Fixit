import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_notification.dart';
import '../../services/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'chat_page.dart';
import 'request_details_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key, required this.isWorkerView});

  final bool isWorkerView;

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppController>().markNotificationsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final text = app.strings;
    final notifications = app.notifications;

    return Scaffold(
      appBar: AppBar(title: Text(text.notifications)),
      body: notifications.isEmpty
          ? Center(child: Text(text.noNotificationsYet))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemBuilder: (context, index) {
                final item = notifications[index];
                return InkWell(
                  onTap: () => _handleTap(context, app, item),
                  borderRadius: BorderRadius.circular(22),
                  child: GlassCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _colorFor(item.type).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _iconFor(item.type),
                            color: _colorFor(item.type),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.body,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat(
                                  'MMM d, h:mm a',
                                ).format(item.createdAt),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemCount: notifications.length,
            ),
    );
  }

  void _handleTap(
    BuildContext context,
    AppController app,
    AppNotification item,
  ) {
    if (item.threadId != null) {
      final matches = app.visibleThreads
          .where((entry) => entry.id == item.threadId)
          .toList();
      final thread = matches.isEmpty ? null : matches.first;
      if (thread != null) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ChatPage(thread: thread, isWorkerView: widget.isWorkerView),
          ),
        );
        return;
      }
    }
    if (item.requestId != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RequestDetailsPage(
            jobId: item.requestId!,
            isWorkerView: widget.isWorkerView,
          ),
        ),
      );
    }
  }

  static IconData _iconFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.request:
        return Icons.assignment_turned_in_outlined;
      case AppNotificationType.message:
        return Icons.chat_bubble_outline_rounded;
      case AppNotificationType.earning:
        return Icons.payments_outlined;
      case AppNotificationType.system:
        return Icons.info_outline_rounded;
    }
  }

  static Color _colorFor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.request:
        return AppColors.primary;
      case AppNotificationType.message:
        return const Color(0xFF468CD8);
      case AppNotificationType.earning:
        return AppColors.success;
      case AppNotificationType.system:
        return AppColors.warning;
    }
  }
}
