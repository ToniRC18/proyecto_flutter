import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/notifications/notification_handler.dart';
import 'core/onboarding/onboarding_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/notifications/notification_service.dart';
import 'core/offline/models/cached_account.dart';
import 'core/offline/models/cached_transaction.dart';
import 'core/offline/models/pending_operation.dart';
import 'core/offline/providers/connectivity_provider.dart';
import 'core/offline/providers/offline_queue_provider.dart';
import 'core/offline/services/connectivity_service.dart';
import 'core/offline/services/hive_cache_service.dart';
import 'core/offline/services/offline_queue_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(10)) {
    Hive.registerAdapter(PendingOperationAdapter());
  }
  if (!Hive.isAdapterRegistered(11)) {
    Hive.registerAdapter(CachedTransactionAdapter());
  }
  if (!Hive.isAdapterRegistered(12)) {
    Hive.registerAdapter(CachedAccountAdapter());
  }

  final connectivityService = ConnectivityService();
  await connectivityService.initialize();

  final queueService = OfflineQueueService();
  await queueService.initialize();

  final cacheService = HiveCacheService();
  await cacheService.initialize();

  // Inicialización de Supabase con URL y ANON KEY
  await Supabase.initialize(
    url: 'https://uzttgvjntpusacoiowyn.supabase.co',
    anonKey: 'sb_publishable_p43FayD3lrzoAzbsPl9t_Q_OBcnjbEC',
  );

  await initializeDateFormatting('es_MX');

  // Inicialización de Firebase + FCM + notificaciones locales
  // IMPORTANTE: antes de correr el proyecto debes ejecutar en terminal:
  //   dart pub global activate flutterfire_cli
  //   flutterfire configure
  // Esto genera lib/firebase_options.dart con las credenciales correctas.
  await const NotificationService().initialize();

  await onboardingService.init();

  // Configuración de la barra de estado
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        connectivityServiceProvider.overrideWithValue(connectivityService),
        offlineQueueServiceProvider.overrideWithValue(queueService),
        hiveCacheServiceProvider.overrideWithValue(cacheService),
      ],
      child: const BrumaApp(),
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
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('es', 'MX'),
        Locale('en'),
      ],
      locale: const Locale('es', 'MX'),
      routerConfig: appRouter,
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationHandler.handlePendingNavigation();
        });
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
