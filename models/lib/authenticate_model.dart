/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

// To parse this JSON data, do
//
//     final authenticate = authenticateFromJson(jsonString);

import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'user_model.dart';
import 'company_model.dart';

Authenticate authenticateFromJson(String str) =>
    Authenticate.fromJson(json.decode(str));

String authenticateToJson(Authenticate data) => json.encode(data.toJson());

class Authenticate extends Equatable {
  final String? apiKey;
  final String? moquiSessionToken;
  final Company? company; //postall address not used here, use user comp address
  final User? user; // user has a company and companyAddress
  final Stats? stats;

  Authenticate({
    this.apiKey,
    this.moquiSessionToken,
    this.company,
    this.user,
    this.stats,
  });

  factory Authenticate.fromJson(Map<String, dynamic> json) => Authenticate(
        apiKey: json["apiKey"],
        moquiSessionToken: json["moquiSessionToken"],
        company:
            json["company"] != null ? Company.fromJson(json["company"]) : null,
        user: json["user"] != null ? User.fromJson(json["user"]) : null,
        stats: json["stats"] != null ? Stats.fromJson(json["stats"]) : null,
      );

  Map<String, dynamic> toJson() => {
        "apiKey": apiKey,
        "moquiSessionToken": moquiSessionToken,
        "company": company?.toJson(),
        "user": user?.toJson(),
        "stats": stats?.toJson(),
      };

  @override
  List<Object?> get props => [
        apiKey,
        moquiSessionToken,
        company,
        user,
        stats,
      ];

  @override
  String toString() => 'Company: $company '
      'User: $user apiKey: '
      '....${apiKey?.substring(apiKey!.length - 10)} ';

  Authenticate copyWith({
    bool clearApiKey = false,
    bool clearCompany = false,
    String? apiKey,
    String? moquiSessionToken,
    Company? company,
    User? user,
    Stats? stats,
  }) =>
      Authenticate(
        apiKey: clearApiKey == true ? null : apiKey ?? this.apiKey,
        moquiSessionToken: moquiSessionToken ?? this.moquiSessionToken,
        company: clearCompany == true ? null : company ?? this.company,
        user: user ?? this.user,
        stats: stats ?? this.stats,
      );
}

Stats statsFromJson(String str) => Stats.fromJson(json.decode(str)["stats"]);
String statsToJson(Stats data) =>
    '{"stats":' + json.encode(data.toJson()) + "}";

class Stats {
  int admins;
  int employees;
  int suppliers;
  int leads;
  int customers;
  int openSlsOrders;
  int openPurOrders;
  int opportunities;
  int myOpportunities;
  int categories;
  int products;
  int assets;
  int salesInvoicesNotPaidCount;
  Decimal? salesInvoicesNotPaidAmount;
  int purchInvoicesNotPaidCount;
  Decimal? purchInvoicesNotPaidAmount;

  Stats({
    this.admins = 0,
    this.employees = 0,
    this.suppliers = 0,
    this.leads = 0,
    this.customers = 0,
    this.openSlsOrders = 0,
    this.openPurOrders = 0,
    this.opportunities = 0,
    this.myOpportunities = 0,
    this.categories = 0,
    this.products = 0,
    this.assets = 0,
    this.salesInvoicesNotPaidCount = 0,
    this.salesInvoicesNotPaidAmount,
    this.purchInvoicesNotPaidCount = 0,
    this.purchInvoicesNotPaidAmount,
  });

  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
        admins: int.parse(json["admins"]),
        employees: int.parse(json["employees"]),
        suppliers: int.parse(json["suppliers"]),
        leads: int.parse(json["leads"]),
        customers: int.parse(json["customers"]),
        openSlsOrders: int.parse(json["openSlsOrders"]),
        openPurOrders: int.parse(json["openPurOrders"]),
        opportunities: int.parse(json["opportunities"]),
        myOpportunities: int.parse(json["myOpportunities"]),
        categories: int.parse(json["categories"]),
        products: int.parse(json["products"]),
        assets: int.parse(json["assets"]),
        salesInvoicesNotPaidCount: int.parse(json["salesInvoicesNotPaidCount"]),
        salesInvoicesNotPaidAmount: json["salesInvoicesNotPaidAmount"] != null
            ? Decimal.parse(json["salesInvoicesNotPaidAmount"])
            : Decimal.parse("0.00"),
        purchInvoicesNotPaidCount: int.parse(json["purchInvoicesNotPaidCount"]),
        purchInvoicesNotPaidAmount: json["purchInvoicesNotPaidAmount"] != null
            ? Decimal.parse(json["purchInvoicesNotPaidAmount"])
            : Decimal.parse("0.00"),
      );

  Map<String, dynamic> toJson() => {
        "admins": admins.toString(),
        "employees": employees.toString(),
        "suppliers": suppliers.toString(),
        "leads": leads.toString(),
        "customers": customers.toString(),
        "openSlsOrders": openSlsOrders.toString(),
        "openPurOrders": openPurOrders.toString(),
        "opportunities": opportunities.toString(),
        "myOpportunities": myOpportunities.toString(),
        "categories": categories.toString(),
        "products": products.toString(),
        "assets": assets.toString(),
        "salesInvoicesNotPaidCount": salesInvoicesNotPaidCount.toString(),
        "salesInvoicesNotPaidAmount": salesInvoicesNotPaidAmount.toString(),
        "purchInvoicesNotPaidCount": purchInvoicesNotPaidCount.toString(),
        "purchInvoicesNotPaidAmount": purchInvoicesNotPaidAmount.toString()
      };
  @override
  String toString() {
    return 'Statistics, admins: $admins';
  }
}
