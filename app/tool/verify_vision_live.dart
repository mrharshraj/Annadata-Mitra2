// Live verification for the direct Gemini vision path.
// Usage: dart run tool/verify_vision_live.dart <image-path>
// Reads GEMINI_ANDROID_KEY from backend/.env (git-ignored). Prints the
// parsed outcome only — never the key. Not part of `flutter test`.
// ignore_for_file: avoid_print (CLI script output is its purpose)
import 'dart:convert';
import 'dart:io';

import 'package:annadata_mitra/data/services/gemini_vision.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    print('USAGE: dart run tool/verify_vision_live.dart <image-path>');
    exit(2);
  }
  final env = File('../backend/.env').readAsStringSync();
  final key = RegExp(r'GEMINI_ANDROID_KEY\s*=\s*(\S+)')
          .firstMatch(env)
          ?.group(1) ??
      RegExp(r'GEMINI_API_KEY\s*=\s*(\S+)').firstMatch(env)?.group(1) ??
      '';
  if (key.isEmpty) {
    print('LIVE VISION: NO KEY CONFIGURED');
    exit(2);
  }
  final bytes = await File(args[0]).readAsBytes();
  print('LIVE VISION: image=${bytes.length} bytes');
  final client = HttpClient();
  try {
    final outcome = await analyzeImageDirect(
      imageBytes: bytes,
      mime: 'image/jpeg',
      apiKey: key,
      post: ({required Uri url, required String body}) async {
        final req = await client.postUrl(url);
        req.headers.contentType = ContentType.json;
        req.write(body);
        final res = await req.close();
        final text = await res.transform(utf8.decoder).join();
        return jsonDecode(text) as Map<String, dynamic>;
      },
      timeout: const Duration(seconds: 90),
    );
    print('LIVE VISION: crop=${outcome.detectedCrop}');
    print('LIVE VISION: issue=${outcome.detectedIssue}');
    print('LIVE VISION: confidence=${outcome.confidence}');
    print('LIVE VISION: uncertain=${outcome.uncertain}');
    print('LIVE VISION: notes=${outcome.notes}');
    print('LIVE VISION: VERIFIED');
  } on VisionFailure catch (e) {
    print('LIVE VISION: FAILED kind=${e.kind} message=${e.message}');
    exit(1);
  } finally {
    client.close();
  }
}
