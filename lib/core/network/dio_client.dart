import 'package:dio/dio.dart';

import '../constants/app_config.dart';

/// Builds the shared [Dio] instance used to talk to the TMDB REST API.
///
/// The API key and common query parameters are attached here via an
/// interceptor so callers never have to construct URLs or repeat auth details.
class DioClient {
  const DioClient._();

  static Dio create() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!AppConfig.useProxy) {
            if (AppConfig.tmdbReadAccessToken.isNotEmpty) {
              options.headers['Authorization'] =
                  'Bearer ${AppConfig.tmdbReadAccessToken}';
            } else if (AppConfig.tmdbApiKey.isNotEmpty) {
              options.queryParameters['api_key'] = AppConfig.tmdbApiKey;
            }
          }

          options.queryParameters = {
            'language': 'en-US',
            ...options.queryParameters,
          };

          // When talking to the proxy, attach a Firebase App Check token so the
          // backend can verify the request came from a genuine build of this
          // app. Wired here as a no-op until App Check is enabled in the app
          // (see SETUP_FIREBASE.md); returns null and is skipped until then.
          if (AppConfig.useProxy) {
            final token = await _appCheckToken?.call();
            if (token != null && token.isNotEmpty) {
              options.headers['X-Firebase-AppCheck'] = token;
            }
          }

          handler.next(options);
        },
      ),
    );

    return dio;
  }

  /// Optional hook that returns the current Firebase App Check token.
  ///
  /// Kept as an injectable function so the network layer has no hard dependency
  /// on the Firebase SDK: `main` sets this once App Check is initialised. Until
  /// then it stays null and the proxy runs with App Check un-enforced.
  static Future<String?> Function()? _appCheckToken;

  static void setAppCheckTokenProvider(Future<String?> Function()? provider) {
    _appCheckToken = provider;
  }
}
