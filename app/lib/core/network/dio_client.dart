import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../constants/api.dart';
import '../auth/auth_provider.dart';

const _storage = FlutterSecureStorage();

Dio buildDio(Ref ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        await ref.read(authNotifierProvider).onUnauthorized();
      } else if (error.response?.statusCode != null &&
          error.response!.statusCode! >= 500) {
        // 5xx 오류는 Sentry에 리포트
        await Sentry.captureException(error,
            stackTrace: error.stackTrace,
            hint: Hint.withMap({'url': error.requestOptions.path}));
      }
      handler.next(error);
    },
  ));

  return dio;
}
