class UserSettings {
  final List<String> favorites;
  final double startingCapital;
  final String currency;
  final String themeMode;

  const UserSettings({
    required this.favorites,
    required this.startingCapital,
    required this.currency,
    required this.themeMode,
  });

  UserSettings copyWith({
    List<String>? favorites,
    double? startingCapital,
    String? currency,
    String? themeMode,
  }) {
    return UserSettings(
      favorites: favorites ?? this.favorites,
      startingCapital: startingCapital ?? this.startingCapital,
      currency: currency ?? this.currency,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
