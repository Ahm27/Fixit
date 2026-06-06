import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/request_job.dart';
import '../services/app_controller.dart';
import '../theme/app_theme.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final RequestStatus status;

  @override
  Widget build(BuildContext context) {
    final text = context.watch<AppController>().strings;
    Color background;
    Color foreground;
    String label;

    switch (status) {
      case RequestStatus.pending:
        background = const Color(0xFFFFF1D8);
        foreground = AppColors.warning;
        label = text.requestStatusLabel('pending');
      case RequestStatus.accepted:
        background = const Color(0xFFDDF5EC);
        foreground = AppColors.primary;
        label = text.requestStatusLabel('accepted');
      case RequestStatus.inProgress:
        background = const Color(0xFFE6F0FF);
        foreground = const Color(0xFF4479D9);
        label = text.requestStatusLabel('in_progress');
      case RequestStatus.completed:
        background = const Color(0xFFDFF5E6);
        foreground = AppColors.success;
        label = text.requestStatusLabel('completed');
      case RequestStatus.cancelled:
        background = const Color(0xFFFBE5E4);
        foreground = AppColors.danger;
        label = text.requestStatusLabel('cancelled');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
