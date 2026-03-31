enum ComplexStatus {
  interested,
  planned,
  visited,
  revisit,
  excluded;

  String get label {
    switch (this) {
      case ComplexStatus.interested:
        return '관심';
      case ComplexStatus.planned:
        return '임장예정';
      case ComplexStatus.visited:
        return '임장완료';
      case ComplexStatus.revisit:
        return '재방문';
      case ComplexStatus.excluded:
        return '제외';
    }
  }

  static ComplexStatus fromString(String value) {
    return ComplexStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ComplexStatus.interested,
    );
  }
}
