class FirestorePaths {
  static const String users = 'users';
  static const String complexes = 'complexes';
  static const String notes = 'notes';
  static const String apiCache = 'apiCache';

  // Subcollections under complexes/{complexId}
  static String inspections(String complexId) =>
      '$complexes/$complexId/inspections';
  static String photos(String complexId, String inspectionId) =>
      '$complexes/$complexId/inspections/$inspectionId/photos';
  static String shares(String complexId) =>
      '$complexes/$complexId/shares';
  static String activityLogs(String complexId) =>
      '$complexes/$complexId/activityLogs';
}
