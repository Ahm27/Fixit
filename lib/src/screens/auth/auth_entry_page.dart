import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../models/account_role.dart';
import '../../services/app_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/primary_button.dart';
import 'auth_page.dart';

class AuthEntryPage extends StatefulWidget {
  const AuthEntryPage({super.key});

  @override
  State<AuthEntryPage> createState() => _AuthEntryPageState();
}

class _AuthEntryPageState extends State<AuthEntryPage> {
  bool _showWelcome = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _showWelcome = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = context.watch<AppController>().strings;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _showWelcome
          ? _WelcomeScreen(text: text)
          : _SplashScreen(text: text),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.text});

  final AppStrings text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFE8F5F1)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.home_repair_service_rounded,
                size: 96,
                color: AppColors.primary,
              ),
              const SizedBox(height: 22),
              Text(
                text.appName,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                text.homeServicesMarketplace,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeScreen extends StatelessWidget {
  const _WelcomeScreen({required this.text});

  final AppStrings text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color(0xFFE8F5F1)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text.welcomeTitle,
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      text.welcomeSubtitle,
                      style: const TextStyle(
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: text.continueAsCustomer,
                onPressed: () => _openAuth(context, AccountRole.customer),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: text.continueAsWorker,
                onPressed: () => _openAuth(context, AccountRole.worker),
                variant: PrimaryButtonVariant.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAuth(BuildContext context, AccountRole role) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AuthPage(initialRole: role)),
    );
  }
}
