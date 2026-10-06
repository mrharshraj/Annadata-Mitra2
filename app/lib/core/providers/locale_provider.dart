import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Active app locale. Defaults to English; profile screen toggles en/hi.
/// Backed by Riverpod so Phase 2+ can persist `preferred_language`.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() => const Locale('en');

  void setLocale(Locale locale) {
    if (locale == state) return;
    state = locale;
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(
  LocaleNotifier.new,
);
