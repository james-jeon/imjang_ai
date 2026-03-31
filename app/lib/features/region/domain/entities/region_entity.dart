class RegionEntity {
  final String code;
  final String sidoName;
  final String? sigunguName;
  final String? dongName;
  final int level;

  RegionEntity({
    required this.code,
    required this.sidoName,
    this.sigunguName,
    this.dongName,
    required this.level,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegionEntity &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() =>
      'RegionEntity(code: $code, sido: $sidoName, sigungu: $sigunguName, dong: $dongName, level: $level)';
}
