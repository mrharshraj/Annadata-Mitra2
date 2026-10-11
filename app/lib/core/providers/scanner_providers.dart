import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/backend_failure.dart';
import '../../core/providers/supabase_providers.dart';
import '../../data/repositories/scanner_repository.dart';

/// Upload goes to the private `crop-scans` bucket under `<uid>/`;
/// analysis goes through the `scan-crop` Edge Function. No FastAPI.
final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  return BackendScannerRepository(
    analyzeWith: ({
      required String imagePath,
      String? fieldId,
    }) async {
      final SupabaseClient client;
      try {
        client = ref.read(supabaseClientProvider);
      } catch (_) {
        throw const BackendFailure.notConfigured();
      }
      if (client.auth.currentSession == null) {
        throw const BackendFailure.authRequired();
      }
      final res = await client.functions.invoke(
        'scan-crop',
        body: {'image_path': imagePath, 'field_id': fieldId},
      );
      if (res.status == 200 && res.data is Map) {
        return (res.data as Map).cast<String, dynamic>();
      }
      if (res.status == 401) throw const BackendFailure.authRequired();
      if (res.status == 403) {
        throw const BackendFailure(
          BackendFailureKind.permission,
          'Not allowed.',
        );
      }
      throw const BackendFailure(
        BackendFailureKind.network,
        'Scan failed. Try again when online.',
      );
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
