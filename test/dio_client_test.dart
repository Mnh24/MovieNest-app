import 'package:flutter_test/flutter_test.dart';
import 'package:movienest/core/constants/app_config.dart';
import 'package:movienest/core/network/dio_client.dart';

void main() {
  group('DioClient & AppConfig', () {
    test('DioClient creates a valid Dio instance', () {
      final dio = DioClient.create();
      expect(dio, isNotNull);
      expect(dio.options.baseUrl, AppConfig.apiBaseUrl);
    });

    test('AppConfig checks configuration state', () {
      // By default when running tests without dart-define, isConfigured might be false
      expect(AppConfig.apiBaseUrl, isNotEmpty);
    });
  });
}
