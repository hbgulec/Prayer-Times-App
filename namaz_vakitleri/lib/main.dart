import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:namaz_vakitleri/app.dart';
import 'package:namaz_vakitleri/core/services/notification_service.dart';
import 'package:namaz_vakitleri/core/services/storage_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A1628),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Init services
  await StorageService.init();
  await NotificationService.init();
  await initializeDateFormatting('tr_TR', null);

  // Request notification permission on startup
  await NotificationService.requestPermission();

  runApp(const App());
}
