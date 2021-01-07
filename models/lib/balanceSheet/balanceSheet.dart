import "class_info_by_id.dart";
import "equity_total_map.dart";
import "liability_equity_total_map.dart";
import "net_asset_total_map.dart";
import "net_income_out.dart";
import 'dart:convert';

BalanceSheet balanceSheetFromJson(String str) =>
    BalanceSheet.fromJson(json.decode(str));
String balanceSheetToJson(BalanceSheet data) => json.encode(data.toJson());

class BalanceSheet {
  NetAssetTotalMap netAssetTotalMap;
  NetIncomeOut netIncomeOut;
  ClassInfoById classInfoById;
  EquityTotalMap equityTotalMap;
  LiabilityEquityTotalMap liabilityEquityTotalMap;

  BalanceSheet({
    this.netAssetTotalMap,
    this.netIncomeOut,
    this.classInfoById,
    this.equityTotalMap,
    this.liabilityEquityTotalMap,
  });

  factory BalanceSheet.fromJson(Map<String, dynamic> json) {
    return BalanceSheet(
      netAssetTotalMap: json['netAssetTotalMap'] == null
          ? null
          : NetAssetTotalMap.fromJson(
              json['netAssetTotalMap'] as Map<String, dynamic>),
      netIncomeOut: json['netIncomeOut'] == null
          ? null
          : NetIncomeOut.fromJson(json['netIncomeOut'] as Map<String, dynamic>),
      classInfoById: json['classInfoById'] == null
          ? null
          : ClassInfoById.fromJson(
              json['classInfoById'] as Map<String, dynamic>),
      equityTotalMap: json['equityTotalMap'] == null
          ? null
          : EquityTotalMap.fromJson(
              json['equityTotalMap'] as Map<String, dynamic>),
      liabilityEquityTotalMap: json['liabilityEquityTotalMap'] == null
          ? null
          : LiabilityEquityTotalMap.fromJson(
              json['liabilityEquityTotalMap'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'netAssetTotalMap': netAssetTotalMap?.toJson(),
      'netIncomeOut': netIncomeOut?.toJson(),
      'classInfoById': classInfoById?.toJson(),
      'equityTotalMap': equityTotalMap?.toJson(),
      'liabilityEquityTotalMap': liabilityEquityTotalMap?.toJson(),
    };
  }

  String toString() => "BalanceSheet:  "
      " CashEquivalent: ${classInfoById.cashEquivalent.totalPostedByTimePeriod.all}"
      " Asset: ${classInfoById.asset.totalPostedByTimePeriod.all}"
      " CurrentAsset: ${classInfoById.currentAsset.totalPostedByTimePeriod.all}";
}
