// To parse this JSON data, do
//     final BalanceSheet = balanceSheetFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';

BalanceSheet balanceSheetFromJson(String str) =>
    BalanceSheet.fromJson(json.decode(str)["balanceSheet"]);
String balanceSheetToJson(BalanceSheet data) =>
    '{"balanceSheet":' + json.encode(data.toJson()) + "}";

class BalanceSheet {
  BalanceSheet({
    this.asset,
    this.liability,
    this.equity,
    this.distribution,
    this.header,
  });

  ClassInfo asset;
  ClassInfo liability;
  ClassInfo equity;
  ClassInfo distribution;
  Header header;

  factory BalanceSheet.fromJson(Map<String, dynamic> json) => BalanceSheet(
        asset: json["asset"] != null ? ClassInfo.fromJson(json["asset"]) : null,
        liability: json["liability"] != null
            ? ClassInfo.fromJson(json["liability"])
            : null,
        equity:
            json["equity"] != null ? ClassInfo.fromJson(json["equity"]) : null,
        distribution: json["distribution"] != null
            ? ClassInfo.fromJson(json["distribution"])
            : null,
        header: Header.fromJson(json["header"]),
      );

  Map<String, dynamic> toJson() => {
        "asset": asset.toJson(),
        "liability": liability.toJson(),
        "equity": equity.toJson(),
        "distribution": distribution.toJson(),
        "header": header.toJson(),
      };
}

class ClassInfo {
  ClassInfo({
    @required this.id,
    @required this.description,
    @required this.periodsAmount,
    @required this.children,
  });

  String id;
  String description;
  List<double> periodsAmount;
  List<ClassInfo> children;

  factory ClassInfo.fromJson(Map<String, dynamic> json) => ClassInfo(
        id: json["id"],
        description: json["description"],
        periodsAmount:
            List<double>.from(json["periodsAmount"].map((x) => x.toDouble())),
        children: List<ClassInfo>.from(
            json["children"].map((x) => ClassInfo.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "description": description,
        "periodsAmount": List<dynamic>.from(periodsAmount.map((x) => x)),
        "children": List<dynamic>.from(children.map((x) => x.toJson())),
      };
}

class Header {
  Header({
    @required this.title,
    @required this.children,
  });

  String title;
  List<String> children;

  factory Header.fromJson(Map<String, dynamic> json) => Header(
        title: json["title"],
        children: List<String>.from(json["children"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "title": title,
        "children": List<dynamic>.from(children.map((x) => x)),
      };
}
