import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_strings.dart';
import 'models/account_role.dart';
import 'screens/auth/auth_entry_page.dart';
import 'screens/auth/profile_completion_page.dart';
import 'screens/home/customer_home_page.dart';
import 'screens/home/worker_home_page.dart';
import 'services/app_controller.dart';
import 'theme/app_theme.dart';
import 'widgets/setup_banner.dart';

class FixItApp extends StatelessWidget {
  const FixItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FixIt',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: context.watch<AppController>().language.locale,
      supportedLocales: AppLanguage.values
          .map((language) => language.locale)
          .toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Consumer<AppController>(
        builder: (context, controller, child) {
          return Stack(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: controller.needsProfileCompletion
                    ? const ProfileCompletionPage()
                    : controller.isAuthenticated
                    ? (controller.currentRole == null
                          ? const SizedBox.shrink()
                          : controller.currentRole == AccountRole.worker
                          ? const WorkerHomePage()
                          : const CustomerHomePage())
                    : const AuthEntryPage(),
              ),
              if (controller.isDemoMode)
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SetupBanner(),
                ),
            ],
          );
        },
      ),
    );
  }
}
