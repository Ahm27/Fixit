import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/services/app_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final controller = AppController();
  await controller.bootstrap();

  runApp(
    ChangeNotifierProvider<AppController>.value(
      value: controller,
      child: const FixItApp(),
    ),
  );
}
