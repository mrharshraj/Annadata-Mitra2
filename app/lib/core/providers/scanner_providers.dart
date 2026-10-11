import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/vision_config.dart';
import '../../core/errors/backend_failure.dart';
import '../../core/providers/supabase_providers.dart';
import '../../data/repositories/scanner_repository.dart';
import '../../data/services/gemini_vision.dart'
    show analyzeImageDirect, VisionFailure, VisionFailureKind;

/// Upload goes to the private `crop-scans` bucket under `<uid>/` (single
/// copy — the scan record references it). Analysis prefers the direct
/// Gemini path when an Android-restricted key was supplied at build time;
/// otherwise the `scan-crop` Edge Function. No FastAPI.
final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  if (VisionConfig.directEnabled) {
    return BackendScannerRepository(
      analyzeWith: ({
        required String imagePath,
        String? fieldId,
      }) => _analyzeDirect(ref, imagePath: imagePath, fieldId: fieldId),
      uploadWith: ({required String localPath, required String fileName}) =>
          _upload(ref, localPath: localPath, fileName: fileName),
    );
  }
  return BackendScannerRepository(
    analyzeWith: ({
      required String imagePath,
      String? fieldId,
    }) async {
      final client = _clientOrThrow(ref);
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
    uploadWith: ({required String localPath, required String fileName}) =>
        _upload(ref, localPath: localPath, fileName: fileName),
  );
});

SupabaseClient _clientOrThrow(Ref ref) {
  try {
    return ref.read(supabaseClientProvider);
  } catch (_) {
    throw const BackendFailure.notConfigured();
  }
}

Future<String> _upload(
  Ref ref, {
  required String localPath,
  required String fileName,
}) async {
  final client = _clientOrThrow(ref);
  final uid = client.auth.currentUser?.id;
  if (uid == null) throw const BackendFailure.authRequired();
  final path = '$uid/$fileName';
  try {
    await client.storage
        .from('crop-scans')
        .upload(
          path,
          File(localPath),
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
  } catch (_) {
    throw const BackendFailure(
      BackendFailureKind.network,
      'Upload failed. Try again when online.',
    );
  }
  return path;
}

/// Direct vision: the single uploaded copy is downloaded back from the
/// private bucket and its bytes go straight to Gemini (base64
/// inline_data); the outcome is persisted with an owner-scoped
/// `crop_scans` insert (RLS insert-own). Returns the Edge-Function-shaped
/// payload so the typed `ScanOutcome` model and UI stay unchanged.
Future<Map<String, dynamic>> _analyzeDirect(
  Ref ref, {
  required String imagePath,
  String? fieldId,
}) async {
  final client = _clientOrThrow(ref);
  final uid = client.auth.currentUser?.id;
  if (uid == null) throw const BackendFailure.authRequired();

  late final List<int> bytes;
  try {
    final blob = await client.storage.from('crop-scans').download(imagePath);
    bytes = blob;
  } catch (_) {
    throw const BackendFailure(
      BackendFailureKind.network,
      'Could not fetch the uploaded image.',
    );
  }

  late final dynamic outcome;
  try {
    outcome = await analyzeImageDirect(
      imageBytes: bytes,
      mime: 'image/jpeg',
      apiKey: VisionConfig.androidKey,
      post: ({required Uri url, required String body}) async {
        final http = HttpClient();
        try {
          final req = await http.postUrl(url);
          req.headers.contentType = ContentType.json;
          req.write(body);
          final res = await req.close();
          final text = await res.transform(utf8.decoder).join();
          return jsonDecode(text) as Map<String, dynamic>;
        } finally {
          http.close();
        }
      },
    );
  } on VisionFailure catch (e) {
    throw BackendFailure(_visionKind(e.kind), e.message);
  }

  Map<String, dynamic> row;
  try {
    final inserted = await client
        .from('crop_scans')
        .insert({
          'profile_id': uid,
          'field_id': fieldId,
          'image_path': imagePath,
          'detected_crop': outcome.detectedCrop,
          'detected_issue': outcome.detectedIssue,
          'confidence': outcome.confidence,
          'analysis': {
            'notes': outcome.notes,
          },
          'status': 'done',
        })
        .select('id')
        .single();
    row = (inserted as Map).cast<String, dynamic>();
  } catch (_) {
    throw const BackendFailure(
      BackendFailureKind.network,
      'Could not save scan.',
    );
  }
  return {
    'scan_id': row['id'],
    'detected_crop': outcome.detectedCrop,
    'detected_issue': outcome.detectedIssue,
    'confidence': outcome.confidence,
    'notes': outcome.notes,
  };
}

BackendFailureKind _visionKind(VisionFailureKind kind) =>
    switch (kind) {
      VisionFailureKind.invalidImage => BackendFailureKind.unknown,
      VisionFailureKind.auth => BackendFailureKind.authRequired,
      VisionFailureKind.rateLimited => BackendFailureKind.network,
      VisionFailureKind.unavailable => BackendFailureKind.network,
      VisionFailureKind.empty => BackendFailureKind.unknown,
    };
