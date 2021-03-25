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

import 'user_model.dart';
import 'company_model.dart';

Authenticate authenticateFromJson(String str) =>
    Authenticate.fromJson(json.decode(str));

String authenticateToJson(Authenticate data) => json.encode(data.toJson());

class Authenticate {
  String? apiKey;
  String? moquiSessionToken;
  Company? company;
  User? user;
  Stats? stats;
  ItemTypes? itemTypes;

  Authenticate({
    this.apiKey,
    this.moquiSessionToken,
    this.company,
    this.user,
    this.stats,
    this.itemTypes,
  });

  factory Authenticate.fromJson(Map<String, dynamic> json) => Authenticate(
        apiKey: json["apiKey"],
        moquiSessionToken: json["moquiSessionToken"],
        company:
            json["company"] != null ? Company.fromJson(json["company"]) : null,
        user: json["user"] != null ? User.fromJson(json["user"]) : null,
        stats: json["stats"] != null ? Stats.fromJson(json["stats"]) : null,
        itemTypes: json["itemTypes"] == null
            ? null
            : ItemTypes.fromJson(json["itemTypes"]),
      );

  Map<String, dynamic> toJson() => {
        "apiKey": apiKey,
        "moquiSessionToken": moquiSessionToken,
        "company": company?.toJson(),
        "user": user?.toJson(),
        "stats": stats?.toJson(),
        "itemTypes": itemTypes == null ? null : itemTypes!.toJson()
      };
  @override
  String toString() => 'Company: ${company?.toString()} '
      'User: ${user?.toString()} apiKey: '
      '....${apiKey?.substring(apiKey!.length - 10)}';
}

Stats statsFromJson(String str) => Stats.fromJson(json.decode(str)["stats"]);
String statsToJson(Stats data) =>
    '{"stats":' + json.encode(data.toJson()) + "}";

class Stats {
  int? admins;
  int? employees;
  int? suppliers;
  int? leads;
  int? customers;
  int? openSlsOrders;
  int? openPurOrders;
  int? opportunities;
  int? myOpportunities;
  int? categories;
  int? products;
  int? salesInvoicesNotPaidCount;
  Decimal? salesInvoicesNotPaidAmount;
  int? purchInvoicesNotPaidCount;
  Decimal? purchInvoicesNotPaidAmount;

  Stats({
    this.admins,
    this.employees,
    this.suppliers,
    this.leads,
    this.customers,
    this.openSlsOrders,
    this.openPurOrders,
    this.opportunities,
    this.myOpportunities,
    this.categories,
    this.products,
    this.salesInvoicesNotPaidCount,
    this.salesInvoicesNotPaidAmount,
    this.purchInvoicesNotPaidCount,
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
        salesInvoicesNotPaidCount: int.parse(json["salesInvoicesNotPaidCount"]),
        salesInvoicesNotPaidAmount:
            Decimal.parse(json["salesInvoicesNotPaidAmount"]),
        purchInvoicesNotPaidCount: int.parse(json["purchInvoicesNotPaidCount"]),
        purchInvoicesNotPaidAmount:
            Decimal.parse(json["purchInvoicesNotPaidAmount"]),
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
        "salesInvoicesNotPaidCount": salesInvoicesNotPaidCount.toString(),
        "salesInvoicesNotPaidAmount": salesInvoicesNotPaidAmount.toString(),
        "purchInvoicesNotPaidCount": purchInvoicesNotPaidCount.toString(),
        "purchInvoicesNotPaidAmount": purchInvoicesNotPaidAmount.toString()
      };
  @override
  String toString() {
    return 'Statistics, products: $products categories: $categories admins: $admins';
  }
}
// To parse this JSON data, do
//
//     final itemTypes = itemTypesFromJson(jsonString);

ItemTypes itemTypesFromJson(String str) =>
    ItemTypes.fromJson(json.decode(str)["itemTypes"]);
String itemTypesToJson(ItemTypes data) =>
    '{"itemTypes":' + json.encode(data.toJson()) + "}";

class ItemTypes {
  ItemTypes({
    this.sales,
    this.purchase,
  });

  List<ItemType>? sales;
  List<ItemType>? purchase;

  factory ItemTypes.fromJson(Map<String, dynamic> json) => ItemTypes(
        sales:
            List<ItemType>.from(json["sales"].map((x) => ItemType.fromJson(x))),
        purchase: List<ItemType>.from(
            json["purchase"].map((x) => ItemType.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "sales": List<dynamic>.from(sales!.map((x) => x.toJson())),
        "purchase": List<dynamic>.from(purchase!.map((x) => x.toJson())),
      };
}

class ItemType {
  ItemType({
    this.itemTypeId,
    this.description,
  });

  String? itemTypeId;
  String? description;

  factory ItemType.fromJson(Map<String, dynamic> json) => ItemType(
        itemTypeId: json["itemTypeId"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
        "itemTypeId": itemTypeId,
        "description": description,
      };
}
