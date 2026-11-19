import 'package:dio/dio.dart';

class ApiClient {
  /// Адрес API можно задать при сборке:
  /// flutter build apk --release --dart-define=API_URL=http://192.168.1.50:8000
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000',
  );

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );

  static String? resolveMediaUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$baseUrl$url';
  }
}
