import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/backend_failure.dart';
import '../../core/providers/api_providers.dart';
import '../../core/providers/supabase_providers.dart';
import '../../data/repositories/scanner_repository.dart';

/// Upload goes to the private `crop-scans` bucket under `<uid>/`;
/// analysis goes through FastAPI. Both resolve lazily (shell-safe).
final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return BackendScannerRepository(
    analyzeWith: ({
      required String imagePath,
      String? fieldId,
    }) async {
      final token = _bearer(ref);
      final res = await dio.post<Map<String, dynamic>>(
        '/scanner/analyze',
        data: {'image_path': imagePath, 'field_id': fieldId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return (res.data ?? {}).cast<String, dynamic>();
    },
    uploadWith: ({
      required String localPath,
      required String fileName,
    }) async {
      final SupabaseClient client;
      try {
        client = ref.read(supabaseClientProvider);
      } catch (_) {
        throw const BackendFailure.notConfigured();
      }
      final uid = client.auth.currentUser?.id;
      if (uid == null) throw const BackendFailure.authRequired();
      final path = '$uid/$fileName';
      await client.storage
          .from('crop-scans')
          .upload(
            path,
            File(localPath),
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
      return path;
    },
  );
});

String _bearer(Ref ref) {
  String? token;
  try {
    token = ref.read(sessionProvider)?.accessToken;
  } catch (_) {
    token = null;
  }
  if (token == null) throw const BackendFailure.authRequired();
  return token;
}
