class AuthAppException implements Exception {
  final String code;
  final String message;

  AuthAppException({required this.code, required this.message});

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;

  NetworkException({this.message = '네트워크 연결을 확인해주세요'});

  @override
  String toString() => message;
}

class UnauthorizedException implements Exception {
  final String message;

  UnauthorizedException({this.message = '인증이 필요합니다'});

  @override
  String toString() => message;
}

class RateLimitException implements Exception {
  final String message;

  RateLimitException({this.message = '요청이 너무 많습니다. 잠시 후 다시 시도해주세요'});

  @override
  String toString() => message;
}

class ServerAppException implements Exception {
  final String message;

  ServerAppException({this.message = '서버 오류가 발생했습니다'});

  @override
  String toString() => message;
}

class XmlParseException implements Exception {
  final String message;

  XmlParseException({this.message = 'XML 파싱 오류가 발생했습니다'});

  @override
  String toString() => message;
}

class SocialAuthCancelledException implements Exception {
  final String message;

  SocialAuthCancelledException({this.message = '소셜 로그인이 취소되었습니다'});

  @override
  String toString() => message;
}

class RegionException implements Exception {
  final String message;

  RegionException({this.message = '지역 데이터 조회 중 오류가 발생했습니다'});

  @override
  String toString() => message;
}

class InvalidRegionCodeException implements Exception {
  final String message;

  InvalidRegionCodeException({this.message = '유효하지 않은 법정동코드입니다'});

  @override
  String toString() => message;
}
