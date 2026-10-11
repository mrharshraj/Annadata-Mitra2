import 'package:annadata_mitra/data/services/gemini_vision.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _ok(String text) => {
  'candidates': [
    {
      'content': {
        'parts': [
          {'text': text},
        ],
      },
    },
  ],
};

void main() {
  test('rejects bad mime and oversize/empty images', () async {
    var calls = 0;
    Future<Map<String, dynamic>> never({
      required Uri url,
      required String body,
    }) async {
      calls++;
      return _ok('CROP: x');
    }
    expect(
      () => analyzeImageDirect(
        imageBytes: [1, 2],
        mime: 'image/gif',
        apiKey: 'k',
        post: never,
      ),
      throwsA(
        isA<VisionFailure>().having(
          (e) => e.kind,
          'kind',
          VisionFailureKind.invalidImage,
        ),
      ),
    );
    expect(calls, 0);
    await expectLater(
      analyzeImageDirect(
        imageBytes: [],
        mime: 'image/jpeg',
        apiKey: 'k',
        post: never,
      ),
      throwsA(isA<VisionFailure>()),
    );
    expect(calls, 0);
  });

  test('parses structured reply + uncertainty flag', () async {
    final out = await analyzeImageDirect(
      imageBytes: [1, 2, 3],
      mime: 'image/jpeg',
      apiKey: 'k',
      post: ({required url, required body}) async =>
          _ok('CROP: Wheat\nISSUE: brown blight\nCONFIDENCE: 0.3\nNEXT: Spray X'),
    );
    expect(out.detectedCrop, 'Wheat');
    expect(out.detectedIssue, 'brown blight');
    expect(out.confidence, 0.3);
    expect(out.uncertain, isTrue);
    expect(out.notes, 'Spray X');
  });

  test('retries transient failures then succeeds', () async {
    var calls = 0;
    final out = await analyzeImageDirect(
      imageBytes: [1],
      mime: 'image/png',
      apiKey: 'k',
      post: ({required url, required body}) async {
        calls++;
        if (calls < 3) throw Exception('flaky');
        return _ok('CROP: Mustard\nISSUE: none visible\nCONFIDENCE: 0.9');
      },
    );
    expect(calls, 3);
    expect(out.detectedCrop, 'Mustard');
    expect(out.detectedIssue, isNull);
    expect(out.uncertain, isFalse);
  });

  test('maps API error codes', () async {
    VisionHttpPost err(int code) =>
        ({required url, required body}) async => {
          'error': {'code': code, 'status': 'X', 'message': 'm'},
        };
    await expectLater(
      analyzeImageDirect(
        imageBytes: [1],
        mime: 'image/jpeg',
        apiKey: 'k',
        post: err(401),
      ),
      throwsA(
        isA<VisionFailure>().having(
          (e) => e.kind,
          'kind',
          VisionFailureKind.auth,
        ),
      ),
    );
    await expectLater(
      analyzeImageDirect(
        imageBytes: [1],
        mime: 'image/jpeg',
        apiKey: 'k',
        post: err(429),
      ),
      throwsA(
        isA<VisionFailure>().having(
          (e) => e.kind,
          'kind',
          VisionFailureKind.rateLimited,
        ),
      ),
    );
    await expectLater(
      analyzeImageDirect(
        imageBytes: [1],
        mime: 'image/jpeg',
        apiKey: 'k',
        post: err(503),
      ),
      throwsA(
        isA<VisionFailure>().having(
          (e) => e.kind,
          'kind',
          VisionFailureKind.unavailable,
        ),
      ),
    );
  });

  test('empty reply is an explicit failure', () async {
    await expectLater(
      analyzeImageDirect(
        imageBytes: [1],
        mime: 'image/jpeg',
        apiKey: 'k',
        post: ({required url, required body}) async => {'x': 1},
      ),
      throwsA(
        isA<VisionFailure>().having(
          (e) => e.kind,
          'kind',
          VisionFailureKind.empty,
        ),
      ),
    );
  });

  test('parseVisionReply clamps confidence + defaults notes', () {
    final o = parseVisionReply('CROP: \nCONFIDENCE: 9\nISSUE: none');
    expect(o.detectedCrop, isNull);
    expect(o.confidence, 1.0);
    expect(o.notes, isNotEmpty);
  });
}
