import "asset.dart";
import "cash_equivalent.dart";
import "current_asset.dart";
import "unEarnedrevenue.dart";

class ClassInfoById {
  CashEquivalent cashEquivalent;
  CurrentAsset currentAsset;
  Asset asset;
  UnEarnedRevenue unEarnedRevenue;

  ClassInfoById(
      {this.cashEquivalent,
      this.currentAsset,
      this.asset,
      this.unEarnedRevenue});

  factory ClassInfoById.fromJson(Map<String, dynamic> json) {
    return ClassInfoById(
      cashEquivalent: json['CASH_EQUIVALENT'] == null
          ? null
          : CashEquivalent.fromJson(
              json['CASH_EQUIVALENT'] as Map<String, dynamic>),
      currentAsset: json['CURRENT_ASSET'] == null
          ? null
          : CurrentAsset.fromJson(
              json['CURRENT_ASSET'] as Map<String, dynamic>),
      asset: json['ASSET'] == null
          ? null
          : Asset.fromJson(json['ASSET'] as Map<String, dynamic>),
      unEarnedRevenue: json['UNEARNED_REVENUE'] == null
          ? null
          : UnEarnedRevenue.fromJson(
              json['UNEARNED_REVENUE'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CASH_EQUIVALENT': cashEquivalent?.toJson(),
      'CURRENT_ASSET': currentAsset?.toJson(),
      'ASSET': asset?.toJson(),
    };
  }
}
