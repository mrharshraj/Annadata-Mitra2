import 'package:annadata_mitra/core/errors/backend_failure.dart';
import 'package:annadata_mitra/data/repositories/scanner_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ScanOutcome maps + flags uncertainty', () {
    final o = ScanOutcome.fromJson({
      'scan_id': 's1',
      'detected_crop': 'Wheat',
      'detected_issue': 'blight',
      'confidence': 0.3,
      'notes': 'Spray X',
    });
    expect(o.uncertain, isTrue);
    expect(o.notes, 'Spray X');
    final sure = ScanOutcome.fromJson({'scan_id': 's2', 'confidence': 0.9});
    expect(sure.uncertain, isFalse);
  });

  test('analyze success passes through', () async {
    final repo = BackendScannerRepository(
      analyzeWith: ({required imagePath, fieldId}) async => {
        'scan_id': 's1',
        'confidence': 0.8,
      },
      uploadWith: ({required localPath, required fileName}) async =>
          'u1/$fileName',
    );
    final res = await repo.analyze(imagePath: 'u1/a.jpg');
    expect((res as Ok<ScanOutcome>).value.scanId, 's1');
  });

  test('auth failure passes through typed', () async {
    final repo = BackendScannerRepository(
      analyzeWith: ({required imagePath, fieldId}) =>
          throw const BackendFailure.authRequired(),
      uploadWith: ({required localPath, required fileName}) =>
          throw const BackendFailure.authRequired(),
    );
    final a = await repo.analyze(imagePath: 'u1/a.jpg');
    expect(
      (a as Err<ScanOutcome>).failure.kind,
      BackendFailureKind.authRequired,
    );
    final u = await repo.upload(localPath: '/tmp/a.jpg', fileName: 'a.jpg');
    expect(
      (u as Err<String>).failure.kind,
      BackendFailureKind.authRequired,
    );
  });

  test('transport failure becomes network error', () async {
    final repo = BackendScannerRepository(
      analyzeWith: ({required imagePath, fieldId}) =>
          throw Exception('down'),
      uploadWith: ({required localPath, required fileName}) =>
          throw Exception('down'),
    );
    final a = await repo.analyze(imagePath: 'u1/a.jpg');
    expect((a as Err<ScanOutcome>).failure.kind, BackendFailureKind.network);
  });
}
