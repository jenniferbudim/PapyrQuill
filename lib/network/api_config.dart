import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the server address and the shared Dio client.
///
/// In the Kotlin app the address was a hardcoded constant in RetrofitClient.kt.
/// Here it is saved in preferences and can be changed from the app, so the same
/// build works on a phone (your PC's Wi-Fi IP) and on Windows (localhost).
class ApiConfig {
  ApiConfig._(this._prefs, String baseUrl)
      : dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
            contentType: Headers.jsonContentType,
            // Let the data source read error bodies instead of throwing.
            validateStatus: (_) => true,
          ),
        );

  static const _key = 'api_base_url';

  /// Same default the Android app shipped with. Change it in the app.
  static const defaultBaseUrl = 'http://192.168.72.143/papyrquill/api/';

  final SharedPreferences _prefs;
  final Dio dio;

  static Future<ApiConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ApiConfig._(prefs, _normalize(prefs.getString(_key) ?? defaultBaseUrl));
  }

  String get baseUrl => dio.options.baseUrl;

  Future<void> setBaseUrl(String url) async {
    final normalized = _normalize(url);
    dio.options.baseUrl = normalized;
    await _prefs.setString(_key, normalized);
  }

  static String _normalize(String url) {
    var u = url.trim();
    if (u.isEmpty) return defaultBaseUrl;
    if (!u.startsWith('http://') && !u.startsWith('https://')) u = 'http://$u';
    if (!u.endsWith('/')) u = '$u/';
    return u;
  }
}
