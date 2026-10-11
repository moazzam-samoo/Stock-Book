import 'package:stock_investment_tracker/domain/entities/tax_settings.dart';

class TaxSettingsModel {
  final bool taxEnabled;
  final double? cdcPerShare;
  final double? psxLagaRate;
  final double? secpLagaRate;
  final double? nccplRate;
  final double? commissionRate;
  final double? sstRate;
  final double? otherCharges;
  final double? cgtRate;

  const TaxSettingsModel({
    this.taxEnabled = false,
    this.cdcPerShare,
    this.psxLagaRate,
    this.secpLagaRate,
    this.nccplRate,
    this.commissionRate,
    this.sstRate,
    this.otherCharges,
    this.cgtRate,
  });

  factory TaxSettingsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TaxSettingsModel();
    return TaxSettingsModel(
      taxEnabled: (json['taxEnabled'] as bool?) ?? false,
      cdcPerShare: (json['cdcPerShare'] as num?)?.toDouble(),
      psxLagaRate: (json['psxLagaRate'] as num?)?.toDouble(),
      secpLagaRate: (json['secpLagaRate'] as num?)?.toDouble(),
      nccplRate: (json['nccplRate'] as num?)?.toDouble(),
      commissionRate: (json['commissionRate'] as num?)?.toDouble(),
      sstRate: (json['sstRate'] as num?)?.toDouble(),
      otherCharges: (json['otherCharges'] as num?)?.toDouble(),
      cgtRate: (json['cgtRate'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taxEnabled': taxEnabled,
      'cdcPerShare': cdcPerShare,
      'psxLagaRate': psxLagaRate,
      'secpLagaRate': secpLagaRate,
      'nccplRate': nccplRate,
      'commissionRate': commissionRate,
      'sstRate': sstRate,
      'otherCharges': otherCharges,
      'cgtRate': cgtRate,
    };
  }

  TaxSettings toEntity() {
    return TaxSettings(
      taxEnabled: taxEnabled,
      cdcPerShare: cdcPerShare,
      psxLagaRate: psxLagaRate,
      secpLagaRate: secpLagaRate,
      nccplRate: nccplRate,
      commissionRate: commissionRate,
      sstRate: sstRate,
      otherCharges: otherCharges,
      cgtRate: cgtRate,
    );
  }

  static TaxSettingsModel fromEntity(TaxSettings entity) {
    return TaxSettingsModel(
      taxEnabled: entity.taxEnabled,
      cdcPerShare: entity.cdcPerShare,
      psxLagaRate: entity.psxLagaRate,
      secpLagaRate: entity.secpLagaRate,
      nccplRate: entity.nccplRate,
      commissionRate: entity.commissionRate,
      sstRate: entity.sstRate,
      otherCharges: entity.otherCharges,
      cgtRate: entity.cgtRate,
    );
  }
}
