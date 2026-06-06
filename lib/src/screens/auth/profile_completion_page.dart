import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/account_role.dart';
import '../../services/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';

class ProfileCompletionPage extends StatefulWidget {
  const ProfileCompletionPage({super.key});

  @override
  State<ProfileCompletionPage> createState() => _ProfileCompletionPageState();
}

class _ProfileCompletionPageState extends State<ProfileCompletionPage> {
  final _formKey = GlobalKey<FormState>();
  AccountRole? _role;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _cityController;
  final _experienceController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _bioController = TextEditingController();
  String _selectedCategory = 'Plumbing';
  bool _didSeedFields = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _cityController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _experienceController.dispose();
    _nationalIdController.dispose();
    _hourlyRateController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final text = controller.strings;
    if (!_didSeedFields) {
      _didSeedFields = true;
      _role = controller.pendingRole;
      _nameController.text = controller.pendingFullName;
      _selectedCategory = controller.serviceCategories.first;
    }
    final role = _role ?? controller.pendingRole;
    return Scaffold(
      appBar: AppBar(title: Text(text.completeProfileTitle)),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFE7F5F0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.almostThere,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      controller.pendingEmail,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: AccountRole.values.map((role) {
                        final active = role == _role;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: role == AccountRole.customer ? 8 : 0,
                              left: role == AccountRole.worker ? 8 : 0,
                            ),
                            child: InkWell(
                              onTap: () => setState(() => _role = role),
                              borderRadius: BorderRadius.circular(18),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.primary
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: active
                                        ? AppColors.primary
                                        : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  role == AccountRole.worker
                                      ? text.workerRole
                                      : text.customerRole,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: active
                                        ? Colors.white
                                        : AppColors.text,
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
              const SizedBox(height: 20),
              _buildField(_nameController, text.fullName, text: text),
              const SizedBox(height: 14),
              _buildField(
                _phoneController,
                text.phoneNumber,
                text: text,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _buildField(_cityController, text.city, text: text),
              if (role == AccountRole.worker) ...[
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(labelText: text.serviceCategory),
                  items: controller.serviceCategories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _selectedCategory = value);
                  },
                ),
                const SizedBox(height: 14),
                _buildField(
                  _experienceController,
                  text.yearsExperience,
                  text: text,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _buildField(
                  _nationalIdController,
                  text.nationalId,
                  text: text,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),
                _buildField(
                  _hourlyRateController,
                  text.hourlyRate,
                  text: text,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _bioController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: text.shortBio,
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return text.requiredField(text.shortBio);
                    }
                    return null;
                  },
                ),
              ],
              if (controller.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage!,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              PrimaryButton(
                label: text.finishSetup,
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  if (role == AccountRole.worker) {
                    final experience = int.tryParse(
                      _experienceController.text.trim(),
                    );
                    final hourlyRate = double.tryParse(
                      _hourlyRateController.text.trim(),
                    );
                    if (experience == null || hourlyRate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(text.validNumbersMessage)),
                      );
                      return;
                    }
                  }
                  await controller.completeGoogleProfile(
                    role: role,
                    fullName: _nameController.text.trim(),
                    phone: _phoneController.text.trim(),
                    city: _cityController.text.trim(),
                    serviceCategory: role == AccountRole.worker
                        ? _selectedCategory
                        : null,
                    yearsExperience: role == AccountRole.worker
                        ? int.parse(_experienceController.text.trim())
                        : null,
                    nationalId: role == AccountRole.worker
                        ? _nationalIdController.text.trim()
                        : null,
                    hourlyRate: role == AccountRole.worker
                        ? double.parse(_hourlyRateController.text.trim())
                        : null,
                    bio: role == AccountRole.worker
                        ? _bioController.text.trim()
                        : null,
                  );
                },
                isBusy: controller.isBusy,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    required dynamic text,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if ((value ?? '').trim().isEmpty) {
          return text.requiredField(label);
        }
        return null;
      },
    );
  }
}
