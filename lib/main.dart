import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

void main() {
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
      // GoRouter toma control total de la navegación declarativa
      routerConfig: appRouter,
    );
  }
}