import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/account_role.dart';
import '../../services/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key, this.initialRole = AccountRole.customer});

  final AccountRole initialRole;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late AccountRole _role;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole;
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    final text = controller.strings;
    if (controller.needsProfileCompletion || controller.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }

    return Scaffold(
      appBar: AppBar(title: Text(text.authTitle)),
      body: SafeArea(
        top: false,
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
                  const Text(
                    'FixIt',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text.authSubtitle(_role),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.muted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                ],
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text.authHint,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
              label: text.continueWithGoogle,
              onPressed: () async {
                await controller.continueWithGoogle(preferredRole: _role);
              },
              isBusy: controller.isBusy,
            ),
          ],
        ),
      ),
    );
  }
}
