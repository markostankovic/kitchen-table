import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/sharing/shared_import_listener.dart';
import 'core/supabase/supabase_client.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  runApp(const ProviderScope(child: KitchenTableApp()));
}

class KitchenTableApp extends ConsumerWidget {
  const KitchenTableApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(goRouterProvider);
    // Wrapping the router rather than sitting inside it: a share can arrive
    // before any screen exists, and the listener navigates through GoRouter
    // rather than a BuildContext.
    return SharedImportListener(
      child: MaterialApp.router(
        title: 'Kitchen Table',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        routerConfig: router,
      ),
    );
  }
}
