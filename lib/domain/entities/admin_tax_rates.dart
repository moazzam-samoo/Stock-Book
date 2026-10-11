import 'package:equatable/equatable.dart';

/// Global default broker charge and tax rates configured by the Admin in Firebase.
/// These apply automatically to all users unless a user overrides a specific rate.
class AdminTaxRates extends Equatable {
  final double cdcPerShare;
  final double psxLagaRate;
  final double secpLagaRate;
  final double nccplRate;
  final double commissionRate;
  final double sstRate;
  final double otherCharges;
  final double cgtRate;

  const AdminTaxRates({
    this.cdcPerShare = 0.0025,
    this.psxLagaRate = 0.0000425,
    this.secpLagaRate = 0.000006,
    this.nccplRate = 0.0000418,
    this.commissionRate = 0.0,
    this.sstRate = 0.0,
    this.otherCharges = 0.0,
    this.cgtRate = 0.0,
  });

  /// Hardcoded fallback representing standard Pakistan Stock Exchange (PSX) charges.
  /// Used if the Firebase document has not been created yet or on first offline launch.
  static const AdminTaxRates psxDefaults = AdminTaxRates();

  AdminTaxRates copyWith({
    double? cdcPerShare,
    double? psxLagaRate,
    double? secpLagaRate,
    double? nccplRate,
    double? commissionRate,
    double? sstRate,
    double? otherCharges,
    double? cgtRate,
  }) {
    return AdminTaxRates(
      cdcPerShare: cdcPerShare ?? this.cdcPerShare,
      psxLagaRate: psxLagaRate ?? this.psxLagaRate,
      secpLagaRate: secpLagaRate ?? this.secpLagaRate,
      nccplRate: nccplRate ?? this.nccplRate,
      commissionRate: commissionRate ?? this.commissionRate,
      sstRate: sstRate ?? this.sstRate,
      otherCharges: otherCharges ?? this.otherCharges,
      cgtRate: cgtRate ?? this.cgtRate,
    );
  }

  @override
  List<Object?> get props => [
        cdcPerShare,
        psxLagaRate,
        secpLagaRate,
        nccplRate,
        commissionRate,
        sstRate,
        otherCharges,
        cgtRate,
      ];
}
