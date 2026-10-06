import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'routing/app_router.dart';

void main() {
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
      routerConfig: buildRouter(),
    );
  }
}
