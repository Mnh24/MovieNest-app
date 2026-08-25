/// A domain-level representation of something that went wrong.
///
/// Failures carry a user-friendly [message] so the presentation layer never
/// has to surface raw exceptions or stack traces to the user.
sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType($message)';
}

/// No connectivity or the request could not reach the server.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Check your internet connection and try again.',
  ]);
}

/// The server responded with an error status code.
class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Something went wrong on our end. Please try again.',
  ]);
}

/// The API key is missing or was rejected by TMDB.
class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Unable to authenticate with the movie service.',
  ]);
}

/// The response could not be parsed into the expected shape.
class ParsingFailure extends Failure {
  const ParsingFailure([
    super.message = 'We received an unexpected response. Please try again.',
  ]);
}

/// Anything not covered by the more specific failures.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'Something went wrong. Please try again.',
  ]);
}
