enum ShareRole {
  owner,
  editor,
  viewer;

  String get label {
    switch (this) {
      case ShareRole.owner:
        return '소유자';
      case ShareRole.editor:
        return '편집자';
      case ShareRole.viewer:
        return '뷰어';
    }
  }

  static ShareRole fromString(String value) {
    return ShareRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ShareRole.viewer,
    );
  }
}
