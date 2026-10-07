import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/supabase_providers.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'routing/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Live backend only when credentials were supplied at build time.
  // UI-shell mode (Phase 1 behaviour) otherwise — no crash, no fake auth.
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      // Supabase renamed the anon key to "publishable key"; same value/role.
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }
  runApp(const ProviderScope(child: AnnadataMitraApp()));
}

class AnnadataMitraApp extends ConsumerWidget {
  const AnnadataMitraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'Annadata Mitra',
      theme: buildAppTheme(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: buildRouter(
        refreshListenable: ref.watch(authRefreshProvider),
        isSignedIn: () => ref.read(sessionProvider) != null,
      ),
    );
  }
}
