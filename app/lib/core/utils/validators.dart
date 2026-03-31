class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '이메일을 입력해 주세요';
    }
    // Simple email regex: has local part, @, and domain with dot
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value)) {
      return '올바른 이메일 형식이 아닙니다';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '비밀번호를 입력해 주세요';
    }
    if (value.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다';
    }
    return null;
  }

  static String? validatePasswordConfirm(String? password, String? confirm) {
    if (confirm == null || confirm.isEmpty || password != confirm) {
      return '비밀번호가 일치하지 않습니다';
    }
    return null;
  }
}
