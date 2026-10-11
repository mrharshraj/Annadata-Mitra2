import 'dart:async';
import 'dart:convert';

// Pure-Dart direct Gemini vision client (no Flutter imports so it stays
// runnable under plain `dart run` verification scripts).
//
// Security contract: the API key is passed per call by the wiring layer
// (build-time --dart-define). This file never sources, stores, logs, or
// defaults a key. Production keys MUST be Android-restricted (package +
// SHA-1) in Google AI Studio; an unrestricted key must never ship.

const String _kModel =
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent';

const Set<String> allowedMime = {'image/jpeg', 'image/png', 'image/webp'};
const int maxBytes = 8 * 1024 * 1024;
const int maxAttempts = 3;

/// Injectable HTTP POST for tests (production: dart:io HttpClient).
typedef VisionHttpPost =
    Future<Map<String, dynamic>> Function({
      required Uri url,
      required String body,
    });

class VisionFailure implements Exception {
  const VisionFailure(this.kind, this.message);

  final VisionFailureKind kind;
  final String message;

  @override
  String toString() => 'VisionFailure($kind): $message';
}

enum VisionFailureKind { invalidImage, auth, rateLimited, unavailable, empty }

class VisionOutcome {
  const VisionOutcome({
    this.detectedCrop,
    this.detectedIssue,
    this.confidence = 0,
    this.notes = '',
  });

  final String? detectedCrop;
  final String? detectedIssue;
  final double confidence;
  final String notes;

  bool get uncertain => confidence < 0.5;
}

/// Validates inputs, POSTs image bytes directly as base64 `inline_data`,
/// retries transient failures, and parses the structured reply.
/// Throws [VisionFailure] (never raw exceptions, never key material).
Future<VisionOutcome> analyzeImageDirect({
  required List<int> imageBytes,
  required String mime,
  required String apiKey,
  required VisionHttpPost post,
  Duration timeout = const Duration(seconds: 45),
}) async {
  if (!allowedMime.contains(mime)) {
    throw VisionFailure(
      VisionFailureKind.invalidImage,
      'Unsupported image type: $mime.',
    );
  }
  if (imageBytes.isEmpty || imageBytes.length > maxBytes) {
    throw const VisionFailure(
      VisionFailureKind.invalidImage,
      'Image must be non-empty and under 8 MB.',
    );
  }
  if (apiKey.isEmpty) {
    throw const VisionFailure(
      VisionFailureKind.auth,
      'Vision API key not configured.',
    );
  }

  final body = jsonEncode({
    'system_instruction': {
      'parts': [
        {
          'text':
              "You are a plant pathologist assistant. Look at this crop photo and "
              "reply with: most likely crop, most likely visible issue (or 'none "
              "visible'), a confidence score between 0 and 1, and one practical "
              "next step. If unsure, say so and keep confidence below 0.5. "
              "Format: CROP: ... ISSUE: ... CONFIDENCE: ... NEXT: ...",
        },
      ],
    },
    'contents': [
      {
        'parts': [
          {
            'inline_data': {
              'mime_type': mime,
              'data': base64Encode(imageBytes),
            },
          },
        ],
      },
    ],
  });

  Map<String, dynamic>? data;
  int attempt = 0;
  // Key travels as a query param per Gemini REST docs, over TLS only.
  final url = Uri.parse('$_kModel?key=$apiKey');
  while (true) {
    attempt++;
    try {
      data = await post(url: url, body: body).timeout(timeout);
      break;
    } on TimeoutException {
      if (attempt >= maxAttempts) {
        throw const VisionFailure(
          VisionFailureKind.unavailable,
          'Vision request timed out.',
        );
      }
      await Future<void>.delayed(Duration(seconds: attempt * 2));
    } catch (_) {
      if (attempt >= maxAttempts) {
        throw const VisionFailure(
          VisionFailureKind.unavailable,
          'Vision service unreachable.',
        );
      }
      await Future<void>.delayed(Duration(seconds: attempt * 2));
    }
  }

  // API-level errors arrive as {error: {code, status, message}}.
  final err = data['error'];
  if (err is Map) {
    final code = err['code'];
    if (code == 400 || code == 401 || code == 403) {
      throw const VisionFailure(
        VisionFailureKind.auth,
        'Vision key rejected. Check key restrictions.',
      );
    }
    if (code == 429) {
      throw const VisionFailure(
        VisionFailureKind.rateLimited,
        'Too many requests. Try again shortly.',
      );
    }
    throw const VisionFailure(
      VisionFailureKind.unavailable,
      'Vision provider error.',
    );
  }
  dynamic text;
  try {
    text = data['candidates'][0]['content']['parts'][0]['text'];
  } catch (_) {
    text = null;
  }
  if (text is! String || text.trim().isEmpty) {
    throw const VisionFailure(
      VisionFailureKind.empty,
      'Vision returned no result.',
    );
  }
  return parseVisionReply(text);
}

/// Parses the CROP/ISSUE/CONFIDENCE/NEXT contract. Pure + total.
VisionOutcome parseVisionReply(String text) {
  String? crop;
  String? issue;
  String? next;
  var confidence = 0.0;
  for (final line in text.split('\n')) {
    final sep = line.indexOf(':');
    if (sep < 0) continue;
    final key = line.substring(0, sep).trim().toUpperCase();
    final val = line.substring(sep + 1).trim();
    if (key == 'CROP') {
      crop = val.isEmpty ? null : val;
    } else if (key == 'ISSUE') {
      issue = val.isEmpty || val.toUpperCase().startsWith('NONE')
          ? null
          : val;
    } else if (key == 'CONFIDENCE') {
      final n = double.tryParse(val);
      confidence = n == null ? 0.0 : n.clamp(0.0, 1.0);
    } else if (key == 'NEXT') {
      next = val.isEmpty ? null : val;
    }
  }
  return VisionOutcome(
    detectedCrop: crop,
    detectedIssue: issue,
    confidence: confidence,
    notes: next ?? 'Consult a local agronomist to confirm.',
  );
}
