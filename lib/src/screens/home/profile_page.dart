import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/account_role.dart';
import '../../services/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/avatar_badge.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/primary_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppController>();
    final text = app.strings;
    final role = app.currentRole;
    final customer = app.customerProfile;
    final worker = app.workerProfile;
    final name = customer?.fullName ?? worker?.fullName ?? text.profile;
    final email = customer?.email ?? worker?.email ?? '';
    final phone = customer?.phone ?? worker?.phone ?? '';
    final city = customer?.city ?? worker?.city ?? '';
    final avatarUrl = customer?.avatarUrl ?? worker?.avatarUrl;

    final content = ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        GlassCard(
          child: Column(
            children: [
              Stack(
                children: [
                  if (avatarUrl != null)
                    CircleAvatar(
                      radius: 44,
                      backgroundImage: NetworkImage(avatarUrl),
                    )
                  else
                    AvatarBadge(
                      initials: customer?.initials ?? worker?.initials ?? 'FX',
                      size: 88,
                    ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: InkWell(
                      onTap: _uploadAvatar,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(email, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 4),
              Text(phone, style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 4),
              Text(city, style: const TextStyle(color: AppColors.muted)),
              if (role == AccountRole.worker && worker != null) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    _InfoPill(label: worker.serviceCategory),
                    _InfoPill(
                      label:
                          '${text.availability}: ${worker.isAvailable ? text.available : text.offline}',
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 2),
        _ActionCard(
          icon: Icons.edit_outlined,
          title: text.editProfile,
          subtitle: text.manageAccount,
          onTap: _openEditProfile,
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.bug_report_outlined,
          title: text.reportBug,
          subtitle: text.supportSubtitle,
          onTap: () => _openSupportSheet(type: 'bug'),
        ),
        const SizedBox(height: 12),
        _ActionCard(
          icon: Icons.support_agent_rounded,
          title: text.openSupportTicket,
          subtitle: text.supportSubtitle,
          onTap: () => _openSupportSheet(type: 'support'),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text.languageLabel,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: AppLanguage.values.map((language) {
                  final selected = app.language == language;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: language == AppLanguage.english ? 8 : 0,
                        left: language == AppLanguage.arabic ? 8 : 0,
                      ),
                      child: InkWell(
                        onTap: () =>
                            context.read<AppController>().setLanguage(language),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            language.nativeLabel,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selected ? Colors.white : AppColors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: Text(text.profile)),
      body: SafeArea(top: false, child: content),
    );
  }

  Future<void> _uploadAvatar() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null || !mounted) {
      return;
    }

    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    await context.read<AppController>().uploadCurrentUserAvatar(
      bytes,
      file.name,
    );
  }

  Future<void> _openEditProfile() async {
    final app = context.read<AppController>();
    final text = app.strings;
    final role = app.currentRole;
    final customer = app.customerProfile;
    final worker = app.workerProfile;
    final fullNameController = TextEditingController(
      text: customer?.fullName ?? worker?.fullName ?? '',
    );
    final phoneController = TextEditingController(
      text: customer?.phone ?? worker?.phone ?? '',
    );
    final cityController = TextEditingController(
      text: customer?.city ?? worker?.city ?? '',
    );
    final experienceController = TextEditingController(
      text: worker?.yearsExperience.toString() ?? '',
    );
    final nationalIdController = TextEditingController(
      text: worker?.nationalId ?? '',
    );
    final hourlyRateController = TextEditingController(
      text: worker?.hourlyRate.toStringAsFixed(0) ?? '',
    );
    final bioController = TextEditingController(text: worker?.bio ?? '');
    var selectedCategory =
        worker?.serviceCategory ?? app.serviceCategories.first;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text.editProfile,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _SheetField(
                  controller: fullNameController,
                  label: text.fullName,
                ),
                const SizedBox(height: 12),
                _SheetField(
                  controller: phoneController,
                  label: text.phoneNumber,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _SheetField(controller: cityController, label: text.city),
                if (role == AccountRole.worker) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: InputDecoration(
                      labelText: text.serviceCategory,
                    ),
                    items: app.serviceCategories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        selectedCategory = value;
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _SheetField(
                    controller: experienceController,
                    label: text.yearsExperience,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _SheetField(
                    controller: nationalIdController,
                    label: text.nationalId,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _SheetField(
                    controller: hourlyRateController,
                    label: text.hourlyRate,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: text.shortBio,
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: text.cancel,
                        onPressed: () => Navigator.of(context).pop(),
                        variant: PrimaryButtonVariant.outline,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: text.saveChanges,
                        onPressed: () async {
                          if (fullNameController.text.trim().isEmpty ||
                              phoneController.text.trim().isEmpty ||
                              cityController.text.trim().isEmpty) {
                            return;
                          }
                          if (role == AccountRole.worker) {
                            final years = int.tryParse(
                              experienceController.text.trim(),
                            );
                            final rate = double.tryParse(
                              hourlyRateController.text.trim(),
                            );
                            if (years == null || rate == null) {
                              if (!mounted) {
                                return;
                              }
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(text.validNumbersMessage),
                                ),
                              );
                              return;
                            }
                          }

                          await app.updateCurrentProfile(
                            fullName: fullNameController.text.trim(),
                            phone: phoneController.text.trim(),
                            city: cityController.text.trim(),
                            serviceCategory: role == AccountRole.worker
                                ? selectedCategory
                                : null,
                            yearsExperience: role == AccountRole.worker
                                ? int.tryParse(experienceController.text.trim())
                                : null,
                            nationalId: role == AccountRole.worker
                                ? nationalIdController.text.trim()
                                : null,
                            hourlyRate: role == AccountRole.worker
                                ? double.tryParse(
                                    hourlyRateController.text.trim(),
                                  )
                                : null,
                            bio: role == AccountRole.worker
                                ? bioController.text.trim()
                                : null,
                          );
                          if (mounted && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSupportSheet({required String type}) async {
    final app = context.read<AppController>();
    final text = app.strings;
    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  type == 'bug' ? text.reportBug : text.openSupportTicket,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                _SheetField(
                  controller: subjectController,
                  label: text.subject,
                  hintText: type == 'bug'
                      ? text.bugSubjectHint
                      : text.supportSubjectHint,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: text.message,
                    hintText: text.describeIssue,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: text.cancel,
                        onPressed: () => Navigator.of(context).pop(),
                        variant: PrimaryButtonVariant.outline,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: text.submit,
                        onPressed: () async {
                          if (subjectController.text.trim().isEmpty ||
                              messageController.text.trim().isEmpty) {
                            return;
                          }
                          final submitted = await app.submitSupportTicket(
                            type: type,
                            subject: subjectController.text.trim(),
                            message: messageController.text.trim(),
                          );
                          if (!mounted || !context.mounted) {
                            return;
                          }
                          if (!submitted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  app.errorMessage ?? text.supportSendFailed,
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(text.supportSent)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.muted, height: 1.3),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.hintText,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, hintText: hintText),
    );
  }
}
