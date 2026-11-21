import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/main_nav_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    const ProviderScope(
      child: LeveledUpApp(),
    ),
  );
}

class LeveledUpApp extends ConsumerWidget {
  const LeveledUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(
      authProvider.select((s) => s.isAuthenticated),
    );

    return MaterialApp(
      title: 'LeveledUp — ATS Scanner & Career Companion',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      theme: AppTheme.darkTheme,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 360),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final scale = Tween<double>(begin: 0.96, end: 1.0).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: scale,
              child: AnimatedBuilder(
                animation: animation,
                builder: (context, inner) => IgnorePointer(
                  ignoring: animation.status != AnimationStatus.completed,
                  child: inner,
                ),
                child: child,
              ),
            ),
          );
        },
        child: isAuthenticated
            ? const MainNavScreen(key: ValueKey('main_nav'))
            : const AuthScreen(key: ValueKey('auth_screen')),
      ),
    );
  }
}
