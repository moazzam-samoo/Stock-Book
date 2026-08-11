import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stock_investment_tracker/domain/entities/withdrawal.dart';
import 'package:stock_investment_tracker/core/utils/timestamp_converter.dart';

part 'withdrawal_model.freezed.dart';

@freezed
abstract class WithdrawalModel with _$WithdrawalModel {
  const factory WithdrawalModel({
    required String id,
    @TimestampConverter() required DateTime date,
    required double amount,
    @Default('') String note,
  }) = _WithdrawalModel;

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    if (json['date'] is Timestamp) {
      parsedDate = (json['date'] as Timestamp).toDate();
    } else if (json['date'] is String) {
      parsedDate = DateTime.tryParse(json['date'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return WithdrawalModel(
      id: (json['id'] as String?) ?? '',
      date: parsedDate,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      note: (json['note'] as String?) ?? '',
    );
  }
}

extension WithdrawalModelExtension on WithdrawalModel {
  /// Manual toJson since we use a custom fromJson (no .g.dart generated).
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'date': Timestamp.fromDate(date),
      'amount': amount,
      'note': note,
    };
  }

  Withdrawal toEntity() {
    return Withdrawal(id: id, date: date, amount: amount, note: note);
  }

  static WithdrawalModel fromEntity(Withdrawal entity) {
    return WithdrawalModel(
      id: entity.id,
      date: entity.date,
      amount: entity.amount,
      note: entity.note,
    );
  }
}
