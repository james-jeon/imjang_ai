import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:imjang_app/features/public_api/domain/entities/apt_list_item.dart';

/// 검색 화면 상태
class ComplexSearchState {
  final List<AptListItem> searchResults;
  final bool isLoading;
  final String? error;
  final Set<String> registeredApiCodes; // 이미 등록된 단지 publicApiCode 집합

  const ComplexSearchState({
    this.searchResults = const [],
    this.isLoading = false,
    this.error,
    this.registeredApiCodes = const {},
  });

  ComplexSearchState copyWith({
    List<AptListItem>? searchResults,
    bool? isLoading,
    String? error,
    Set<String>? registeredApiCodes,
    bool clearError = false,
  }) {
    return ComplexSearchState(
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      registeredApiCodes: registeredApiCodes ?? this.registeredApiCodes,
    );
  }
}

/// 검색 상태 프로바이더
final complexSearchStateProvider =
    StateProvider<ComplexSearchState>((_) => const ComplexSearchState());
