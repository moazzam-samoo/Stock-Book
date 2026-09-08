class UserSettings {
  final List<String> favorites;
  final double startingCapital;
  final String currency;
  final String themeMode;
  final Map<String, int> stockColors;
  final List<String> pinnedTickers;
  final bool isPremiumUnlocked;

  const UserSettings({
    required this.favorites,
    required this.startingCapital,
    required this.currency,
    required this.themeMode,
    this.stockColors = const {},
    this.pinnedTickers = const [],
    this.isPremiumUnlocked = false,
  });

  UserSettings copyWith({
    List<String>? favorites,
    double? startingCapital,
    String? currency,
    String? themeMode,
    Map<String, int>? stockColors,
    List<String>? pinnedTickers,
    bool? isPremiumUnlocked,
  }) {
    return UserSettings(
      favorites: favorites ?? this.favorites,
      startingCapital: startingCapital ?? this.startingCapital,
      currency: currency ?? this.currency,
      themeMode: themeMode ?? this.themeMode,
      stockColors: stockColors ?? this.stockColors,
      pinnedTickers: pinnedTickers ?? this.pinnedTickers,
      isPremiumUnlocked: isPremiumUnlocked ?? this.isPremiumUnlocked,
    );
  }
}
