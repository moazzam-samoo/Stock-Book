class FirestorePaths {
  static String user(String uid) => 'users/$uid';
  static String lots(String uid) => 'users/$uid/lots';
  static String lot(String uid, String lotId) => 'users/$uid/lots/$lotId';
  static String sales(String uid, String lotId) => 'users/$uid/lots/$lotId/sales';
  static String sale(String uid, String lotId, String saleId) => 'users/$uid/lots/$lotId/sales/$saleId';
  static String positions(String uid) => 'users/$uid/positions';
  static String position(String uid, String positionId) => 'users/$uid/positions/$positionId';
  static String settings(String uid) => 'users/$uid/settings/preferences';
  static String withdrawals(String uid) => 'users/$uid/withdrawals';
  static String withdrawal(String uid, String withdrawalId) => 'users/$uid/withdrawals/$withdrawalId';
  static String priceAlerts(String uid) => 'users/$uid/price_alerts';
  static String priceAlert(String uid, String alertId) => 'users/$uid/price_alerts/$alertId';
  static String marketPrices() => 'market_prices';
  static String marketPrice(String ticker) => 'market_prices/$ticker';

  // Market Status
  static String marketStatus() => 'market_status/current';

  // Tickers
  static String tickersDoc() => 'tickers/all';
}
