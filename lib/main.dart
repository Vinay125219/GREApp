import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import './services/local_cache_service.dart';
import './services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('[main] Failed to initialize Supabase: $e');
    // Continue app startup — login screen will retry initialization
  }

  // Initialize local cache (evict stale entries from previous sessions)
  try {
    await LocalCacheService.instance.evictExpired();
    debugPrint('[main] Local cache initialized');
  } catch (e) {
    debugPrint('[main] LocalCacheService init error: $e');
  }

  // Initialize offline queue and register Supabase sync handlers
  try {
    await SupabaseService.instance.initOfflineQueue();
    debugPrint('[main] Offline queue initialized');
  } catch (e) {
    debugPrint('[main] OfflineQueueService init error: $e');
  }

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  // Guard with kIsWeb: SystemChrome.setPreferredOrientations is a no-op on web
  // but wrapping in Future.wait delays runApp unnecessarily on web builds.
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'GREApp CoachLMS',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          scrollBehavior: const AppScrollBehavior(),
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.initial,
        );
      },
    );
  }
}
