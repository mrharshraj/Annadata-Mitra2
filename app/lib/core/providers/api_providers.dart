import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';

/// Shared Dio instance for all repositories (Phase 3+).
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio);
