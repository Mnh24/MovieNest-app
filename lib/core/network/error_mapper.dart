import 'package:dio/dio.dart';

import '../errors/failure.dart';

/// Returns a user-friendly message for any error, mapping it to a [Failure]
/// first when it isn't already one. Never surfaces raw exception text.
String messageForError(Object error) => mapError(error).message;

/// Translates low-level networking and parsing exceptions into domain
/// [Failure]s carrying user-friendly messages.
Failure mapError(Object error) {
  if (error is Failure) return error;

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkFailure('The request timed out. Please try again.');
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        if (status == 401 || status == 403) return const AuthFailure();
        if (status == 404) {
          return const ServerFailure('The requested content was not found.');
        }
        return const ServerFailure();
      case DioExceptionType.cancel:
        return const UnexpectedFailure('The request was cancelled.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const NetworkFailure();
    }
  }

  if (error is TypeError || error is FormatException) {
    return const ParsingFailure();
  }

  return const UnexpectedFailure();
}
