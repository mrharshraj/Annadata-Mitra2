import 'package:annadata_mitra/l10n/app_localizations.dart';
import 'package:annadata_mitra/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(const ProviderScope(child: AnnadataMitraApp()));
  await tester.pump(const Duration(milliseconds: 100));
}

/// Splash auto-advances after 2s; flush the timer so teardown stays clean.
Future<void> _flushSplashTimer(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  testWidgets('App boots to splash with EN strings', (tester) async {
    await _pumpApp(tester);
    expect(find.text('ANNADATA MITRA'), findsWidgets);
    await _flushSplashTimer(tester);
  });

  testWidgets('App exposes EN + HI localizations', (tester) async {
    await _pumpApp(tester);
    await _flushSplashTimer(tester);
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(AppLocalizations(const Locale('hi')).navHome, 'होम');
    expect(AppLocalizations(const Locale('en')).navHome, 'HOME');
  });

  test('Supported locales are en + hi', () {
    expect(
      AppLocalizations.supportedLocales.map((e) => e.languageCode),
      containsAll(['en', 'hi']),
    );
  });
}
