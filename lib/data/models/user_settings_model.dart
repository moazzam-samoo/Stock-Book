import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stock_investment_tracker/domain/entities/user_settings.dart';

part 'user_settings_model.freezed.dart';
part 'user_settings_model.g.dart';

@freezed
abstract class UserSettingsModel with _$UserSettingsModel {
  const factory UserSettingsModel({
    @Default([]) List<String> favorites,
    @Default(10000.0) double startingCapital,
    @Default('PKR') String currency,
    @Default('dark') String themeMode,
  }) = _UserSettingsModel;

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) => _$UserSettingsModelFromJson(json);
}

extension UserSettingsModelExtension on UserSettingsModel {
  UserSettings toEntity() {
    return UserSettings(
      favorites: favorites,
      startingCapital: startingCapital,
      currency: currency,
      themeMode: themeMode,
    );
  }

  static UserSettingsModel fromEntity(UserSettings entity) {
    return UserSettingsModel(
      favorites: entity.favorites,
      startingCapital: entity.startingCapital,
      currency: entity.currency,
      themeMode: entity.themeMode,
    );
  }
}
