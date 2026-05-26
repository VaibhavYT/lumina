import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lumina/core/constants/app_constants.dart';
import 'package:lumina/core/extensions/context_extensions.dart';
import 'package:lumina/core/theme/app_theme.dart';
import 'package:lumina/core/theme/theme_provider.dart';
import 'package:lumina/router/app_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await Hive.initFlutter();
  await Hive.openBox<dynamic>(AppConstants.settingsBox);

  await _initializeSupabase();

  runApp(const ProviderScope(child: AppRoot()));
}

Future<void> _initializeSupabase() async {
  try {
    await dotenv.load(fileName: '.env', isOptional: true);
    final url =
        dotenv.env[AppConstants.supabaseUrlKey] ??
        dotenv.env[AppConstants.supabaseUrlAliasKey];
    final anonKey =
        dotenv.env[AppConstants.supabaseAnonKey] ??
        dotenv.env[AppConstants.supabaseAnonAliasKey];

    if (url == null || anonKey == null || url.isEmpty || anonKey.isEmpty) {
      debugPrint('Lumina: Supabase credentials not found; local mode active.');
      return;
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
  } on Object catch (error) {
    debugPrint('Lumina: Supabase initialization skipped: $error');
  }
}

class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final colors = context.colors;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            statusBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarIconBrightness: isDark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: ColoredBox(
            color: colors.backgroundPrimary,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
