abstract class Failure {
  final String message;
  const Failure(this.message);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class AuthFailure extends Failure {
  final String code;
  const AuthFailure({required this.code, required String message})
      : super(message);
}
