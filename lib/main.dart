import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/navigation/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/settings_provider.dart';

import 'features/background/background_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final container = ProviderContainer();
  
  // Initialize settings database first
  final settingsRepo = container.read(settingsRepositoryProvider);
  await settingsRepo.init();
  
  // Initialize background module (which sets up window/tray/auto-start/service)
  await container.read(backgroundModuleProvider.notifier).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BackupVaultApp(),
    ),
  );
}

class BackupVaultApp extends ConsumerWidget {
  const BackupVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    ThemeMode themeMode;
    switch (theme.toLowerCase()) {
      case 'light':
        themeMode = ThemeMode.light;
        break;
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        themeMode = ThemeMode.system;
        break;
    }

    return MaterialApp.router(
      title: 'BackupVault',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: goRouter,
    );
  }
}
