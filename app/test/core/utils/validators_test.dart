// TC-VAL-001 ~ TC-VAL-010
// 대상: lib/core/utils/validators.dart
// 레이어: Unit — 순수 유효성 검증 함수

import 'package:flutter_test/flutter_test.dart';
import 'package:imjang_app/core/utils/validators.dart';

void main() {
  group('Validators.validateEmail', () {
    test('TC-VAL-001: 유효한 이메일 형식은 null을 반환한다', () {
      expect(Validators.validateEmail('user@example.com'), isNull);
      expect(Validators.validateEmail('test.name+tag@sub.domain.co.kr'), isNull);
    });

    test('TC-VAL-002: @가 없는 이메일은 에러 메시지를 반환한다', () {
      expect(
        Validators.validateEmail('invalid-email'),
        equals('올바른 이메일 형식이 아닙니다'),
      );
    });

    test('TC-VAL-003: 도메인이 없는 이메일은 에러 메시지를 반환한다', () {
      expect(
        Validators.validateEmail('user@'),
        equals('올바른 이메일 형식이 아닙니다'),
      );
    });

    test('TC-VAL-004: 로컬파트가 없는 이메일은 에러 메시지를 반환한다', () {
      expect(
        Validators.validateEmail('@domain.com'),
        equals('올바른 이메일 형식이 아닙니다'),
      );
    });

    test('TC-VAL-005: 빈 이메일은 입력 요청 메시지를 반환한다', () {
      expect(
        Validators.validateEmail(''),
        equals('이메일을 입력해 주세요'),
      );
      expect(
        Validators.validateEmail(null),
        equals('이메일을 입력해 주세요'),
      );
    });

    test('TC-VAL-005b: 공백만 있는 이메일은 입력 요청 메시지를 반환한다', () {
      expect(
        Validators.validateEmail('   '),
        equals('이메일을 입력해 주세요'),
      );
    });
  });

  group('Validators.validatePassword', () {
    test('TC-VAL-006: 8자 이상 비밀번호는 null을 반환한다', () {
      expect(Validators.validatePassword('password123'), isNull);
      expect(Validators.validatePassword('12345678'), isNull);
      expect(Validators.validatePassword('abcdefgh'), isNull);
    });

    test('TC-VAL-007: 7자 비밀번호는 에러 메시지를 반환한다', () {
      expect(
        Validators.validatePassword('short12'),
        equals('비밀번호는 8자 이상이어야 합니다'),
      );
    });

    test('TC-VAL-007b: 1자 비밀번호도 에러 메시지를 반환한다', () {
      expect(
        Validators.validatePassword('a'),
        equals('비밀번호는 8자 이상이어야 합니다'),
      );
    });

    test('TC-VAL-008: 빈 비밀번호는 입력 요청 메시지를 반환한다', () {
      expect(
        Validators.validatePassword(''),
        equals('비밀번호를 입력해 주세요'),
      );
      expect(
        Validators.validatePassword(null),
        equals('비밀번호를 입력해 주세요'),
      );
    });

    test('TC-VAL-008b: 공백만 있는 비밀번호는 입력 요청 메시지를 반환한다', () {
      expect(
        Validators.validatePassword('   '),
        equals('비밀번호를 입력해 주세요'),
      );
    });
  });

  group('Validators.validatePasswordConfirm', () {
    test('TC-VAL-009: 비밀번호와 확인 값이 일치하면 null을 반환한다', () {
      expect(
        Validators.validatePasswordConfirm('password123', 'password123'),
        isNull,
      );
    });

    test('TC-VAL-010: 비밀번호와 확인 값이 불일치하면 에러 메시지를 반환한다', () {
      expect(
        Validators.validatePasswordConfirm('password123', 'different456'),
        equals('비밀번호가 일치하지 않습니다'),
      );
    });

    test('TC-VAL-010b: 확인 값이 비어있으면 에러 메시지를 반환한다', () {
      expect(
        Validators.validatePasswordConfirm('password123', ''),
        equals('비밀번호가 일치하지 않습니다'),
      );
      expect(
        Validators.validatePasswordConfirm('password123', null),
        equals('비밀번호가 일치하지 않습니다'),
      );
    });
  });
}
