import 'package:equatable/equatable.dart';
import 'package:stock_investment_tracker/domain/entities/admin_tax_rates.dart';

/// User-level tax and broker charge configuration.
/// All rate fields are nullable:
/// - If null, the rate automatically inherits the global [AdminTaxRates] set in Firebase.
/// - If non-null, the user's custom override takes precedence.
/// - [taxEnabled] is the master switch. When false, zero taxes are deducted across the app.
class TaxSettings extends Equatable {
  final bool taxEnabled;

  // Per-share fee (absolute Rs amount per share, e.g. 0.0025)
  final double? cdcPerShare;

  // % of trade value (fraction, e.g. 0.0000425 for 0.00425%)
  final double? psxLagaRate;
  final double? secpLagaRate;
  final double? nccplRate;

  // % of trade value (broker specific)
  final double? commissionRate;

  // % of commission amount
  final double? sstRate;

  // Fixed Rs amount per trade
  final double? otherCharges;

  // % of net profit (sell side only, applied when net profit > 0)
  final double? cgtRate;

  const TaxSettings({
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

  /// Resolves the final effective rates by merging user overrides with admin defaults.
  EffectiveTaxRates resolveEffective(AdminTaxRates admin) {
    return EffectiveTaxRates(
      taxEnabled: taxEnabled,
      cdcPerShare: cdcPerShare ?? admin.cdcPerShare,
      psxLagaRate: psxLagaRate ?? admin.psxLagaRate,
      secpLagaRate: secpLagaRate ?? admin.secpLagaRate,
      nccplRate: nccplRate ?? admin.nccplRate,
      commissionRate: commissionRate ?? admin.commissionRate,
      sstRate: sstRate ?? admin.sstRate,
      otherCharges: otherCharges ?? admin.otherCharges,
      cgtRate: cgtRate ?? admin.cgtRate,
    );
  }

  /// True if the user has customized any rate away from the defaults.
  bool get hasCustomOverrides =>
      cdcPerShare != null ||
      psxLagaRate != null ||
      secpLagaRate != null ||
      nccplRate != null ||
      commissionRate != null ||
      sstRate != null ||
      otherCharges != null ||
      cgtRate != null;

  TaxSettings copyWith({
    bool? taxEnabled,
    double? cdcPerShare,
    double? psxLagaRate,
    double? secpLagaRate,
    double? nccplRate,
    double? commissionRate,
    double? sstRate,
    double? otherCharges,
    double? cgtRate,
    bool clearOverrides = false,
  }) {
    if (clearOverrides) {
      return TaxSettings(taxEnabled: taxEnabled ?? this.taxEnabled);
    }
    return TaxSettings(
      taxEnabled: taxEnabled ?? this.taxEnabled,
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
        taxEnabled,
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

/// Resolved effective rates ready to be passed into calculators.
class EffectiveTaxRates extends Equatable {
  final bool taxEnabled;
  final double cdcPerShare;
  final double psxLagaRate;
  final double secpLagaRate;
  final double nccplRate;
  final double commissionRate;
  final double sstRate;
  final double otherCharges;
  final double cgtRate;

  const EffectiveTaxRates({
    required this.taxEnabled,
    required this.cdcPerShare,
    required this.psxLagaRate,
    required this.secpLagaRate,
    required this.nccplRate,
    required this.commissionRate,
    required this.sstRate,
    required this.otherCharges,
    required this.cgtRate,
  });

  /// Disabled / zero tax instance
  static const EffectiveTaxRates disabled = EffectiveTaxRates(
    taxEnabled: false,
    cdcPerShare: 0.0,
    psxLagaRate: 0.0,
    secpLagaRate: 0.0,
    nccplRate: 0.0,
    commissionRate: 0.0,
    sstRate: 0.0,
    otherCharges: 0.0,
    cgtRate: 0.0,
  );

  @override
  List<Object?> get props => [
        taxEnabled,
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
