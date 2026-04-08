import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Supabase con URL y ANON KEY
  await Supabase.initialize(
    url: 'https://uzttgvjntpusacoiowyn.supabase.co',
    anonKey: 'sb_publishable_p43FayD3lrzoAzbsPl9t_Q_OBcnjbEC',
  );

  // Inicialización de Firebase + FCM + notificaciones locales
  // IMPORTANTE: antes de correr el proyecto debes ejecutar en terminal:
  //   dart pub global activate flutterfire_cli
  //   flutterfire configure
  // Esto genera lib/firebase_options.dart con las credenciales correctas.
  await NotificationService.init();

  // Configuración de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: BrumaApp(),
    ),
  );
}

class BrumaApp extends StatelessWidget {
  const BrumaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Bruma Personal Finance',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}