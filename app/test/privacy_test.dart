import 'package:annadata_mitra/core/providers/weather_providers.dart';
import 'package:annadata_mitra/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
      child: const AnnadataMitraApp(),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

Element _routerContext(WidgetTester tester) =>
    // Any descendant of MaterialApp.router sits below the GoRouter scope.
    tester.element(find.text('ANNADATA MITRA'));

void main() {
  testWidgets('privacy screen is reachable without auth', (tester) async {
    await _pumpApp(tester);
    // Flush the splash auto-advance timer first, then navigate.
    await tester.pump(const Duration(seconds: 3));
    GoRouter.of(_routerContext(tester)).go('/privacy');
    await tester.pumpAndSettle();
    expect(find.text('PRIVACY POLICY'), findsOneWidget);
    expect(
      find.textContaining('DELETION', skipOffstage: false),
      findsWidgets,
    );
  });

  testWidgets('sign-in links to privacy policy', (tester) async {
    await _pumpApp(tester);
    await tester.pump(const Duration(seconds: 3));
    GoRouter.of(_routerContext(tester)).go('/sign-in');
    await tester.pumpAndSettle();
    expect(find.text('PRIVACY POLICY'), findsOneWidget);
  });
}
