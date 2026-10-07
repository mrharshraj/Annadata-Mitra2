import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../errors/backend_failure.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/repositories.dart';
import '../../data/repositories/supabase_crop_repository.dart';
import '../../data/repositories/supabase_farmer_repository.dart';
import '../../data/repositories/supabase_field_repository.dart';
import '../../data/repositories/supabase_location_repository.dart';
import '../../data/repositories/supabase_task_repository.dart';

/// True once Supabase.initialize ran (main.dart calls it when configured).
/// Tests and UI-shell mode skip init; repositories short-circuit instead.
final supabaseReadyProvider = Provider<bool>(
  (ref) => SupabaseConfig.isConfigured,
);

/// Shared client. Throws [BackendFailure.notConfigured] when credentials
/// were not supplied — widgets must handle via BackendStateView.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (!SupabaseConfig.isConfigured) {
    throw const BackendFailure.notConfigured();
  }
  return Supabase.instance.client;
});

/// Emits on every sign-in/sign-out so go_router can refresh its guard.
final authRefreshProvider = Provider<ValueNotifier<int>>((ref) {
  final tick = ValueNotifier<int>(0);
  if (SupabaseConfig.isConfigured) {
    final sub = Supabase.instance.client.auth.onAuthStateChange.listen(
      (_) => tick.value++,
    );
    ref.onDispose(sub.cancel);
  }
  return tick;
});

/// Current session, or null when signed out / unconfigured.
final sessionProvider = Provider<Session?>((ref) {
  if (!SupabaseConfig.isConfigured) return null;
  ref.watch(authRefreshProvider);
  return Supabase.instance.client.auth.currentSession;
});

final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => SupabaseLocationRepository(ref.watch(supabaseClientProvider)),
);
final farmerRepositoryProvider = Provider<FarmerRepository>(
  (ref) => SupabaseFarmerRepository(ref.watch(supabaseClientProvider)),
);
final fieldRepositoryProvider = Provider<FieldRepository>(
  (ref) => SupabaseFieldRepository(ref.watch(supabaseClientProvider)),
);
final cropRepositoryProvider = Provider<CropRepository>(
  (ref) => SupabaseCropRepository(ref.watch(supabaseClientProvider)),
);
final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => SupabaseTaskRepository(ref.watch(supabaseClientProvider)),
);

/// Own profile; null while signed out. UI distinguishes:
/// - unconfigured → BackendStateView (notConfigured)
/// - signed out → auth gate
/// - signed in, no row yet → onboarding creates it
final profileProvider = FutureProvider<Profile?>((ref) async {
  if (!SupabaseConfig.isConfigured) {
    throw const BackendFailure.notConfigured();
  }
  ref.watch(authRefreshProvider);
  final repo = ref.watch(farmerRepositoryProvider);
  switch (await repo.profile()) {
    case Ok(:final value):
      return value;
    case Err(:final failure):
      throw failure;
  }
});
