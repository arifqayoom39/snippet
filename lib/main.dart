import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snippet/common/common.dart';
import 'package:snippet/common/intro_screen.dart';
import 'package:snippet/common/splash_screen.dart';
import 'package:snippet/features/auth/controller/auth_controller.dart';
import 'package:snippet/features/home/view/home_view.dart';
import 'package:snippet/services/push_notification_service.dart';
import 'package:snippet/theme/app_theme.dart';
import 'package:snippet/theme/pallete.dart';
import 'package:snippet/theme/theme_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Create the ProviderContainer to initialize providers before runApp
  final container = ProviderContainer();
  
  // Initialize theme, then force light theme for first-time users
  await container.read(themeProvider.notifier).initTheme();
  
  // Set light theme as default for the first launch
  final prefs = await ThemeStorage.getTheme();
  if (prefs == null) {
    await container.read(themeProvider.notifier).setLightMode();
  }
  
  // Initialize OneSignal
  await container.read(pushNotificationServiceProvider).initializeOneSignal();
  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch for theme changes
    final isDarkMode = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'X',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: ref.watch(currentUserAccountProvider).when(
            data: (user) {
              if (user != null) {
                return const HomeView();
              }
              // For new users, show the intro screen
              return const IntroScreen();
            },
            error: (error, st) => ErrorPage(
              error: error.toString(),
            ),
            loading: () => const SplashScreen(),
          ),
    );
  }
}
