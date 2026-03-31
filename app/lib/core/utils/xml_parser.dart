import 'package:xml/xml.dart' as xml;
import 'package:imjang_app/core/error/exceptions.dart';

export 'package:imjang_app/core/error/exceptions.dart' show XmlParseException;

class XmlParser {
  /// Parse a public API XML response and return list of item maps.
  /// Each item's child elements become key-value pairs.
  /// The '거래금액' field values are trimmed of leading/trailing whitespace.
  /// Returns empty list if resultCode != '00' or items is empty.
  /// Throws [XmlParseException] for malformed or empty XML.
  static List<Map<String, String>> parseResponse(String xmlString) {
    if (xmlString.isEmpty) {
      throw XmlParseException(message: 'XML 문자열이 비어있습니다');
    }

    final xml.XmlDocument document;
    try {
      document = xml.XmlDocument.parse(xmlString);
    } catch (e) {
      throw XmlParseException(message: 'XML 파싱 실패: $e');
    }

    // Check resultCode
    final resultCodeElements = document.findAllElements('resultCode');
    if (resultCodeElements.isEmpty) {
      return [];
    }
    final resultCode = resultCodeElements.first.innerText;
    if (resultCode != '00') {
      return [];
    }

    // Find items
    final itemsElements = document.findAllElements('items');
    if (itemsElements.isEmpty) {
      return [];
    }

    final items = itemsElements.first.findElements('item');
    final result = <Map<String, String>>[];

    for (final item in items) {
      final map = <String, String>{};
      for (final child in item.children) {
        if (child is xml.XmlElement) {
          map[child.name.local] = child.innerText.trim();
        }
      }
      result.add(map);
    }

    return result;
  }

  /// Check if the XML response has resultCode '00' (success).
  static bool isSuccessResponse(String xmlString) {
    try {
      final document = xml.XmlDocument.parse(xmlString);
      final resultCodeElements = document.findAllElements('resultCode');
      if (resultCodeElements.isEmpty) return false;
      return resultCodeElements.first.innerText == '00';
    } catch (e) {
      return false;
    }
  }
}
