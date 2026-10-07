import '../../core/errors/backend_failure.dart';

/// Fetch function injected for testability (production: Dio POST).
typedef ScanAnalyzeFetcher =
    Future<Map<String, dynamic>> Function({
      required String imagePath,
      String? fieldId,
    });

/// Upload function injected for testability (production: Storage).
typedef ScanUploader =
    Future<String> Function({
      required String localPath,
      required String fileName,
    });

/// Contract: pick → compress → upload → analyze → typed result.
abstract class ScannerRepository {
  Future<Result<ScanOutcome>> analyze({
    required String imagePath,
    String? fieldId,
  });
  Future<Result<String>> upload({
    required String localPath,
    required String fileName,
  });
}

class ScanOutcome {
  const ScanOutcome({
    required this.scanId,
    this.detectedCrop,
    this.detectedIssue,
    this.confidence = 0,
    this.notes = '',
  });

  final String scanId;
  final String? detectedCrop;
  final String? detectedIssue;
  final double confidence;
  final String notes;

  bool get uncertain => confidence < 0.5;

  factory ScanOutcome.fromJson(Map<String, dynamic> json) => ScanOutcome(
    scanId: json['scan_id'] as String? ?? '',
    detectedCrop: json['detected_crop'] as String?,
    detectedIssue: json['detected_issue'] as String?,
    confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
    notes: json['notes'] as String? ?? '',
  );
}

class BackendScannerRepository implements ScannerRepository {
  BackendScannerRepository({
    required this.analyzeWith,
    required this.uploadWith,
  });

  final ScanAnalyzeFetcher analyzeWith;
  final ScanUploader uploadWith;

  @override
  Future<Result<ScanOutcome>> analyze({
    required String imagePath,
    String? fieldId,
  }) async {
    try {
      final json = await analyzeWith(imagePath: imagePath, fieldId: fieldId);
      return Ok(ScanOutcome.fromJson(json));
    } on BackendFailure catch (e) {
      return Err(e);
    } catch (_) {
      return const Err(
        BackendFailure(
          BackendFailureKind.network,
          'Scan failed. Try again when online.',
        ),
      );
    }
  }

  @override
  Future<Result<String>> upload({
    required String localPath,
    required String fileName,
  }) async {
    try {
      return Ok(await uploadWith(localPath: localPath, fileName: fileName));
    } on BackendFailure catch (e) {
      return Err(e);
    } catch (_) {
      return const Err(
        BackendFailure(
          BackendFailureKind.network,
          'Upload failed. Try again when online.',
        ),
      );
    }
  }
}
