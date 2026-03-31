import 'package:dio/dio.dart';
import 'package:imjang_app/core/error/exceptions.dart';

class DioClient {
  final Dio dio;
  final int maxRetries;

  DioClient({
    required this.dio,
    this.maxRetries = 3,
  });

  /// Exponential backoff delays: 1s, 2s, 4s
  List<Duration> get retryDelays => const [
        Duration(seconds: 1),
        Duration(seconds: 2),
        Duration(seconds: 4),
      ];

  /// Perform a GET request with retry logic (exponential backoff).
  /// Returns the response data as a String.
  /// Throws mapped exceptions for known HTTP error codes.
  Future<String> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    DioException? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await dio.get(
          path,
          queryParameters: queryParameters,
          options: Options(responseType: ResponseType.plain),
        );
        return response.data as String;
      } on DioException catch (e) {
        // For badResponse errors, map immediately without retry
        if (e.type == DioExceptionType.badResponse && e.response != null) {
          _throwMappedException(e);
        }

        lastException = e;

        // If we still have retries left, wait before retrying
        if (attempt < maxRetries) {
          await Future.delayed(retryDelays[attempt]);
          continue;
        }
      }
    }

    // All retries exhausted
    throw NetworkException(
      message: lastException?.message ?? '네트워크 연결을 확인해주세요',
    );
  }

  Never _throwMappedException(DioException e) {
    final statusCode = e.response?.statusCode;
    switch (statusCode) {
      case 401:
        throw UnauthorizedException();
      case 429:
        throw RateLimitException();
      case 500:
      case 502:
      case 503:
        throw ServerAppException();
      default:
        throw NetworkException(
          message: e.message ?? '네트워크 연결을 확인해주세요',
        );
    }
  }
}
