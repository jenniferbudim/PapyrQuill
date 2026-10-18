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
            // Read the reply as text and decode it ourselves, so a PHP error
            // page can be shown in the log instead of a vague FormatException.
            responseType: ResponseType.plain,
            // Let the data source read error bodies instead of throwing.
            validateStatus: (_) => true,
          ),
        );

  static const _key = 'api_base_url';

  /// Same default the Android app shipped with. Change it in the app.
  static const defaultBaseUrl = 'http://192.168.1.11/papyrquill/api/';

  /// Null when preferences could not be opened (the address is then not
  /// remembered between launches, but the app still starts).
  final SharedPreferences? _prefs;
  final Dio dio;

  static Future<ApiConfig> load() async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      // A broken plugin build must not leave the app on a black screen.
      prefs = null;
    }
    String? saved;
    try {
      saved = prefs?.getString(_key);
    } catch (_) {
      saved = null;
    }
    return ApiConfig._(prefs, _normalize(saved ?? defaultBaseUrl));
  }

  String get baseUrl => dio.options.baseUrl;

  Future<void> setBaseUrl(String url) async {
    final normalized = _normalize(url);
    dio.options.baseUrl = normalized;
    try {
      await _prefs?.setString(_key, normalized);
    } catch (_) {
      // Keep the new address for this run even if it cannot be saved.
    }
  }

  static String _normalize(String url) {
    var u = url.trim();
    if (u.isEmpty) return defaultBaseUrl;
    if (!u.startsWith('http://') && !u.startsWith('https://')) u = 'http://$u';
    if (!u.endsWith('/')) u = '$u/';
    return u;
  }
}
