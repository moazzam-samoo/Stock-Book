import 'package:stock_investment_tracker/domain/entities/admin_tax_rates.dart';

class AdminTaxRatesModel {
  final double cdcPerShare;
  final double psxLagaRate;
  final double secpLagaRate;
  final double nccplRate;
  final double commissionRate;
  final double sstRate;
  final double otherCharges;
  final double cgtRate;

  const AdminTaxRatesModel({
    this.cdcPerShare = 0.0025,
    this.psxLagaRate = 0.0000425,
    this.secpLagaRate = 0.000006,
    this.nccplRate = 0.0000418,
    this.commissionRate = 0.0,
    this.sstRate = 0.0,
    this.otherCharges = 0.0,
    this.cgtRate = 0.0,
  });

  factory AdminTaxRatesModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AdminTaxRatesModel();
    return AdminTaxRatesModel(
      cdcPerShare: (json['cdcPerShare'] as num?)?.toDouble() ?? 0.0025,
      psxLagaRate: (json['psxLagaRate'] as num?)?.toDouble() ?? 0.0000425,
      secpLagaRate: (json['secpLagaRate'] as num?)?.toDouble() ?? 0.000006,
      nccplRate: (json['nccplRate'] as num?)?.toDouble() ?? 0.0000418,
      commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 0.0,
      sstRate: (json['sstRate'] as num?)?.toDouble() ?? 0.0,
      otherCharges: (json['otherCharges'] as num?)?.toDouble() ?? 0.0,
      cgtRate: (json['cgtRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
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

  AdminTaxRates toEntity() {
    return AdminTaxRates(
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

  static AdminTaxRatesModel fromEntity(AdminTaxRates entity) {
    return AdminTaxRatesModel(
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
