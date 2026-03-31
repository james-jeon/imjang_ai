// TC-XML-001 ~ TC-XML-007
// 대상: lib/core/utils/xml_parser.dart (S2에서 구현)
// 레이어: Unit — 공공API XML 응답 파싱

import 'package:flutter_test/flutter_test.dart';
import 'package:imjang_app/core/utils/xml_parser.dart';

void main() {
  group('XmlParser.parseResponse', () {
    // 공공API 실제 응답 형식 (국토교통부 아파트매매 실거래가 API 기준)
    const validXmlSingleItem = '''
<?xml version="1.0" encoding="UTF-8"?>
<response>
  <header>
    <resultCode>00</resultCode>
    <resultMsg>NORMAL SERVICE.</resultMsg>
  </header>
  <body>
    <items>
      <item>
        <아파트>래미안</아파트>
        <거래금액> 85,000</거래금액>
        <건축년도>2010</건축년도>
        <년>2024</년>
        <법정동>역삼동</법정동>
        <아파트>래미안역삼</아파트>
        <월>1</월>
        <일>15</일>
        <전용면적>84.98</전용면적>
        <층>12</층>
      </item>
    </items>
    <numOfRows>10</numOfRows>
    <pageNo>1</pageNo>
    <totalCount>1</totalCount>
  </body>
</response>''';

    const validXmlMultipleItems = '''
<?xml version="1.0" encoding="UTF-8"?>
<response>
  <header>
    <resultCode>00</resultCode>
    <resultMsg>NORMAL SERVICE.</resultMsg>
  </header>
  <body>
    <items>
      <item>
        <아파트>래미안역삼</아파트>
        <거래금액> 85,000</거래금액>
        <법정동>역삼동</법정동>
      </item>
      <item>
        <아파트>삼성힐스테이트</아파트>
        <거래금액> 120,000</거래금액>
        <법정동>삼성동</법정동>
      </item>
    </items>
    <numOfRows>10</numOfRows>
    <pageNo>1</pageNo>
    <totalCount>2</totalCount>
  </body>
</response>''';

    const emptyItemsXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<response>
  <header>
    <resultCode>00</resultCode>
    <resultMsg>NORMAL SERVICE.</resultMsg>
  </header>
  <body>
    <items/>
    <numOfRows>10</numOfRows>
    <pageNo>1</pageNo>
    <totalCount>0</totalCount>
  </body>
</response>''';

    const errorResponseXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<response>
  <header>
    <resultCode>03</resultCode>
    <resultMsg>SERVICE NO FOUND</resultMsg>
  </header>
  <body/>
</response>''';

    const malformedXml = '<response><unclosed>';

    test(
      'TC-XML-001: 단건 아이템 XML 파싱 → List<Map> 1개 반환',
      () {
        final result = XmlParser.parseResponse(validXmlSingleItem);

        expect(result, isA<List<Map<String, String>>>());
        expect(result.length, equals(1));
        expect(result.first['아파트'], equals('래미안역삼'));
        expect(result.first['법정동'], equals('역삼동'));
      },
    );

    test(
      'TC-XML-002: 복수 아이템 XML 파싱 → List<Map> n개 반환',
      () {
        final result = XmlParser.parseResponse(validXmlMultipleItems);

        expect(result.length, equals(2));
        expect(result[0]['아파트'], equals('래미안역삼'));
        expect(result[1]['아파트'], equals('삼성힐스테이트'));
        expect(result[1]['거래금액'], equals('120,000'));
      },
    );

    test(
      'TC-XML-003: items가 비어있는 XML 파싱 → 빈 List 반환',
      () {
        final result = XmlParser.parseResponse(emptyItemsXml);

        expect(result, isA<List<Map<String, String>>>());
        expect(result, isEmpty);
      },
    );

    test(
      'TC-XML-004: 에러 응답 XML (resultCode != 00) → 빈 List 반환',
      () {
        final result = XmlParser.parseResponse(errorResponseXml);

        expect(result, isA<List<Map<String, String>>>());
        expect(result, isEmpty);
      },
    );

    test(
      'TC-XML-005: 잘못된 형식의 XML → XmlParseException throw',
      () {
        expect(
          () => XmlParser.parseResponse(malformedXml),
          throwsA(isA<XmlParseException>()),
        );
      },
    );

    test(
      'TC-XML-006: 빈 문자열 입력 → XmlParseException throw',
      () {
        expect(
          () => XmlParser.parseResponse(''),
          throwsA(isA<XmlParseException>()),
        );
      },
    );

    test(
      'TC-XML-007: 거래금액 공백 trim 처리 — 앞뒤 공백 제거',
      () {
        final result = XmlParser.parseResponse(validXmlSingleItem);

        // 공공API는 금액 앞에 공백을 포함하여 응답함 → trim 적용 확인
        expect(result.first['거래금액'], equals('85,000'));
      },
    );
  });

  group('XmlParser.parseResultCode', () {
    test(
      'TC-XML-008: resultCode "00" → true (정상 응답)',
      () {
        const xml = '''
<response>
  <header>
    <resultCode>00</resultCode>
    <resultMsg>NORMAL SERVICE.</resultMsg>
  </header>
  <body/>
</response>''';

        expect(XmlParser.isSuccessResponse(xml), isTrue);
      },
    );

    test(
      'TC-XML-009: resultCode "03" → false (에러 응답)',
      () {
        const xml = '''
<response>
  <header>
    <resultCode>03</resultCode>
    <resultMsg>SERVICE NO FOUND</resultMsg>
  </header>
  <body/>
</response>''';

        expect(XmlParser.isSuccessResponse(xml), isFalse);
      },
    );
  });
}
