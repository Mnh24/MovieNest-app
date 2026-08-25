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
        baseUrl: AppConfig.tmdbBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.queryParameters = {
            'api_key': AppConfig.tmdbApiKey,
            'language': 'en-US',
            ...options.queryParameters,
          };
          handler.next(options);
        },
      ),
    );

    return dio;
  }
}
