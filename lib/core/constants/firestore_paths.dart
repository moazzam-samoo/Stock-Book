class FirestorePaths {
  static String user(String uid) => 'users/$uid';
  static String lots(String uid) => 'users/$uid/lots';
  static String lot(String uid, String lotId) => 'users/$uid/lots/$lotId';
  static String sales(String uid, String lotId) => 'users/$uid/lots/$lotId/sales';
  static String sale(String uid, String lotId, String saleId) => 'users/$uid/lots/$lotId/sales/$saleId';
  static String settings(String uid) => 'users/$uid/settings/preferences';
}
