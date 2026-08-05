// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserSettingsModel _$UserSettingsModelFromJson(Map<String, dynamic> json) =>
    _UserSettingsModel(
      favorites:
          (json['favorites'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      startingCapital: (json['startingCapital'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'PKR',
      themeMode: json['themeMode'] as String? ?? 'dark',
      stockColors:
          (json['stockColors'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toInt()),
          ) ??
          const {},
    );

Map<String, dynamic> _$UserSettingsModelToJson(_UserSettingsModel instance) =>
    <String, dynamic>{
      'favorites': instance.favorites,
      'startingCapital': instance.startingCapital,
      'currency': instance.currency,
      'themeMode': instance.themeMode,
      'stockColors': instance.stockColors,
    };
