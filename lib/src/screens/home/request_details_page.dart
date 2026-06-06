import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/request_job.dart';
import '../../services/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_chip.dart';
import 'chat_page.dart';

class RequestDetailsPage extends StatelessWidget {
  const RequestDetailsPage({
    super.key,
    required this.jobId,
    required this.isWorkerView,
  });

  final String jobId;
  final bool isWorkerView;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final text = app.strings;
    final job = app.requestById(jobId);
    if (job == null) {
      return Scaffold(body: Center(child: Text(text.requestNotFound)));
    }
    final threads = app.visibleThreads;
    final thread = threads.where((item) => item.id == job.threadId).isNotEmpty
        ? threads.firstWhere((item) => item.id == job.threadId)
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(text.requestDetails)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          GlassCard(
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
                          fontSize: 22,
                        ),
                      ),
                    ),
                    StatusChip(status: job.status),
                  ],
                ),
                const SizedBox(height: 12),
                Text(job.description, style: const TextStyle(height: 1.35)),
                const SizedBox(height: 14),
                Text(
                  '${text.serviceCategoryName(job.category)} • ${DateFormat('EEE, MMM d - h:mm a').format(job.scheduledFor)}',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  job.customerAddress,
                  style: const TextStyle(color: AppColors.muted),
                ),
                if (job.workerName != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    text.workerName(job.workerName!),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (job.attachmentUrl != null) ...[
            const SizedBox(height: 14),
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  job.attachmentUrl!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => SizedBox(
                    height: 120,
                    child: Center(child: Text(text.attachmentUnavailable)),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text.serviceStatus,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
                const SizedBox(height: 16),
                ..._timeline(job),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: PrimaryButton(
            label: text.openChat,
            onPressed: thread == null
                ? null
                : () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ChatPage(
                          thread: thread,
                          isWorkerView: isWorkerView,
                        ),
                      ),
                    );
                  },
          ),
        ),
      ),
    );
  }

  List<Widget> _timeline(RequestJob job) {
    // Localized in build tree by reading from inherited widget context later.
    final items = [
      ('request_submitted', true),
      (
        'technician_assigned',
        job.workerId != null ||
            job.status.index >= RequestStatus.accepted.index,
      ),
      ('in_progress', job.status.index >= RequestStatus.inProgress.index),
      ('completed', job.status == RequestStatus.completed),
    ];

    return items.map((entry) {
      final complete = entry.$2;
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Builder(
          builder: (context) {
            final text = context.watch<AppController>().strings;
            final label = switch (entry.$1) {
              'request_submitted' => text.requestSubmitted,
              'technician_assigned' => text.technicianAssigned,
              'in_progress' => text.inProgress,
              _ => text.completed,
            };
            return Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: complete ? AppColors.primary : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: complete ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: complete ? AppColors.text : AppColors.muted,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }).toList();
  }
}
