class ActivityLogEntity {
  final String id;
  final String complexId;
  final String actorId;
  final String actorName;
  final String action;
  final String? targetType;
  final String? targetId;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  ActivityLogEntity({
    required this.id,
    required this.complexId,
    required this.actorId,
    required this.actorName,
    required this.action,
    this.targetType,
    this.targetId,
    this.details,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityLogEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ActivityLogEntity(id: $id, action: $action, actor: $actorName)';
}
