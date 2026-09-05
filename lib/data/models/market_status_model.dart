import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/market_status.dart';

part 'market_status_model.freezed.dart';
part 'market_status_model.g.dart';

@freezed
abstract class MarketStatusModel with _$MarketStatusModel {
  const MarketStatusModel._();

  const factory MarketStatusModel({
    required bool isOpen,
    required String label,
    @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
    required DateTime checkedAt,
  }) = _MarketStatusModel;

  factory MarketStatusModel.fromJson(Map<String, dynamic> json) =>
      _$MarketStatusModelFromJson(json);

  MarketStatus toEntity() {
    return MarketStatus(
      isOpen: isOpen,
      label: label,
      checkedAt: checkedAt,
    );
  }

  factory MarketStatusModel.fromEntity(MarketStatus entity) {
    return MarketStatusModel(
      isOpen: entity.isOpen,
      label: entity.label,
      checkedAt: entity.checkedAt,
    );
  }
}

DateTime _dateFromJson(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  } else if (value is String) {
    return DateTime.parse(value);
  } else if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return DateTime.now(); // Fallback, shouldn't happen with valid data
}

dynamic _dateToJson(DateTime date) {
  return Timestamp.fromDate(date);
}
