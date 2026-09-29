import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/network/demo_config.dart';
import 'core/services/local_notifications.dart';
import 'core/services/push_notifications_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  LocalNotificationsService.init();
  PushNotificationsService.init();
  DemoConfig.load();

  runApp(const ProviderScope(child: CareMateApp()));
}
