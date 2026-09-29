import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/l10n/app_locale.dart';
import 'core/l10n/generated/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/sharing/shared_import_listener.dart';
import 'core/supabase/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_theme_mode.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Portrait only: no screen is laid out for landscape.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  await initSupabase();
  // The theme choice is read before the first frame, so a Dark user never
  // sees a Light flash (D128). The read never throws -- a failure is Light.
  final ProviderContainer container = ProviderContainer();
  await container.read(appThemeModeProvider.future);
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const KitchenTableApp(),
    ),
  );
}

class KitchenTableApp extends ConsumerWidget {
  const KitchenTableApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(goRouterProvider);
    final Locale locale = ref.watch(appLocaleProvider);
    final ThemeMode themeMode =
        ref.watch(appThemeModeProvider).value ?? ThemeMode.light;
    // Wrapping the router rather than sitting inside it: a share can arrive
    // before any screen exists, and the listener navigates through GoRouter
    // rather than a BuildContext.
    return SharedImportListener(
      child: MaterialApp.router(
        title: 'Kitchen Table',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        locale: locale,
        supportedLocales: appSupportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: router,
      ),
    );
  }
}
