import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Centralized HTTP client for FastAPI (Phase 3+).
/// Widgets must never create raw Dio/HttpClient calls — they go through
/// repositories which use this client.
class ApiClient {
  ApiClient({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

  final Dio _dio;

  Dio get dio => _dio;

  /// Health probe for `GET /health` (available from Phase 3).
  Future<bool> ping() async {
    try {
      final res = await _dio.get<dynamic>('/health');
      return res.statusCode == 200;
    } on DioException {
      return false;
    }
  }
}
