import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/worker_profile.dart';
import '../../services/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';

class BookingFlowPage extends StatefulWidget {
  const BookingFlowPage({super.key, required this.initialCategory});

  final String initialCategory;

  @override
  State<BookingFlowPage> createState() => _BookingFlowPageState();
}

class _BookingFlowPageState extends State<BookingFlowPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _budgetController = TextEditingController(text: '180');
  final ImagePicker _picker = ImagePicker();
  late String _category;
  int _step = 0;
  DateTime _scheduledFor = DateTime.now().add(const Duration(hours: 3));
  WorkerProfile? _selectedWorker;
  Uint8List? _attachmentBytes;
  String? _attachmentName;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final text = app.strings;
    final workers = app.workersForCategory(_category);

    return Scaffold(
      appBar: AppBar(title: Text(text.bookService)),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                      height: 6,
                      decoration: BoxDecoration(
                        color: index <= _step
                            ? AppColors.primary
                            : AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _step,
                children: [
                  _buildServiceStep(app),
                  _buildDetailsStep(),
                  _buildWorkerStep(workers),
                  _buildReviewStep(),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    if (_step > 0) ...[
                      Expanded(
                        child: PrimaryButton(
                          label: text.back,
                          onPressed: () => setState(() => _step -= 1),
                          variant: PrimaryButtonVariant.outline,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: PrimaryButton(
                        label: _step == 3
                            ? text.submitRequest
                            : text.continueLabel,
                        onPressed: () async {
                          if (_step < 3) {
                            if (!_canContinue()) {
                              _showValidationError();
                              return;
                            }
                            setState(() => _step += 1);
                            return;
                          }
                          await _submit();
                        },
                        isBusy: app.isBusy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStep(AppController app) {
    final text = app.strings;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      children: [
        Text(
          text.chooseService,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          text.chooseServiceSubtitle,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: app.serviceCategories.map((category) {
            final active = category == _category;
            return ChoiceChip(
              label: Text(text.serviceCategoryName(category)),
              selected: active,
              onSelected: (_) => setState(() => _category = category),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(labelText: text.serviceTitle),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _descriptionController,
          minLines: 4,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: text.describeProblem,
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    final text = context.watch<AppController>().strings;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      children: [
        Text(
          text.addDetails,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          text.addDetailsSubtitle,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        InkWell(
          onTap: _pickDateTime,
          child: GlassCard(
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(DateFormat('EEE, MMM d - h:mm a').format(_scheduledFor)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _addressController,
          decoration: InputDecoration(labelText: text.address),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _budgetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: text.estimatedBudget),
        ),
        const SizedBox(height: 14),
        InkWell(
          onTap: _pickAttachment,
          child: GlassCard(
            child: Row(
              children: [
                const Icon(
                  Icons.photo_camera_back_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _attachmentName ?? text.uploadImage,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_attachmentBytes != null) ...[
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.memory(
              _attachmentBytes!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildWorkerStep(List<WorkerProfile> workers) {
    final text = context.watch<AppController>().strings;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      children: [
        Text(
          text.chooseWorker,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          text.chooseWorkerSubtitle,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        InkWell(
          onTap: () => setState(() => _selectedWorker = null),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _selectedWorker == null
                  ? const Color(0xFFE8F5F1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: _selectedWorker == null
                    ? AppColors.primary
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text.autoMatchLater,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (workers.isEmpty)
          GlassCard(
            child: Text(
              text.noWorkersAvailableAutoMatch,
              style: const TextStyle(color: AppColors.muted),
            ),
          )
        else
          ...workers.map(
            (worker) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => setState(() => _selectedWorker = worker),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _selectedWorker?.id == worker.id
                        ? const Color(0xFFE8F5F1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _selectedWorker?.id == worker.id
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (worker.avatarUrl != null)
                        CircleAvatar(
                          radius: 26,
                          backgroundImage: NetworkImage(worker.avatarUrl!),
                        )
                      else
                        AvatarBadge(initials: worker.initials, size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    worker.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                if (worker.isVerified)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      text.verified,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${text.serviceCategoryName(worker.serviceCategory)} • ${text.yearsExperienceValue(worker.yearsExperience)}',
                              style: const TextStyle(color: AppColors.muted),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              worker.bio,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF2A541),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${worker.rating.toStringAsFixed(1)} • ${text.jobsCountValue(worker.completedJobs)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  text.pricePerHour(worker.hourlyRate),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewStep() {
    final text = context.watch<AppController>().strings;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      children: [
        Text(
          text.reviewBooking,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          text.reviewBookingSubtitle,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.category,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              Text(
                text.serviceCategoryName(_category),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Text(
                text.service,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              Text(
                _titleController.text.trim(),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Text(
                text.description,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              Text(_descriptionController.text.trim()),
              const SizedBox(height: 14),
              Text(
                text.address,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              Text(_addressController.text.trim()),
              const SizedBox(height: 14),
              Text(
                text.preferredTime,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              Text(DateFormat('EEE, MMM d - h:mm a').format(_scheduledFor)),
              const SizedBox(height: 14),
              Text(text.budget, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 6),
              Text(
                text.isArabic
                    ? '${_budgetController.text.trim()} ج.م'
                    : 'EGP ${_budgetController.text.trim()}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Text(text.worker, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 6),
              Text(
                _selectedWorker?.fullName ?? text.autoMatchLater,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _canContinue() {
    switch (_step) {
      case 0:
        return _isServiceStepValid;
      case 1:
        return _isDetailsStepValid;
      case 2:
        return true;
      case 3:
        return true;
      default:
        return false;
    }
  }

  bool get _isServiceStepValid =>
      _titleController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty;

  bool get _isDetailsStepValid {
    final budget = double.tryParse(_budgetController.text.trim());
    return _addressController.text.trim().isNotEmpty &&
        budget != null &&
        budget > 0;
  }

  Future<void> _submit() async {
    final controller = context.read<AppController>();
    if (!_isServiceStepValid || !_isDetailsStepValid) {
      _showValidationError();
      return;
    }
    final budget = double.parse(_budgetController.text.trim());
    await controller.createCustomerRequest(
      category: _category,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      scheduledFor: _scheduledFor,
      estimatedPrice: budget,
      chosenWorker: _selectedWorker,
      attachmentBytes: _attachmentBytes,
      attachmentName: _attachmentName,
    );
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _showValidationError() {
    final text = context.read<AppController>().strings;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text.invalidBookingFields)));
  }

  Future<void> _pickDateTime() async {
    final currentContext = context;
    final date = await showDatePicker(
      context: currentContext,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      initialDate: _scheduledFor,
    );
    if (date == null || !currentContext.mounted) {
      return;
    }
    final time = await showTimePicker(
      context: currentContext,
      initialTime: TimeOfDay.fromDateTime(_scheduledFor),
    );
    if (time == null) {
      return;
    }
    setState(() {
      _scheduledFor = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickAttachment() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) {
      return;
    }
    final bytes = await file.readAsBytes();
    setState(() {
      _attachmentBytes = bytes;
      _attachmentName = file.name;
    });
  }
}
