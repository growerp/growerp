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
//     final company = companyFromJson(jsonString);

import 'dart:convert';
import 'dart:typed_data';

Company companyFromJson(String str) =>
    Company.fromJson(json.decode(str)["company"]);
String companyToJson(Company data) =>
    '{"company":' + json.encode(data.toJson()) + "}";

List<Company> companiesFromJson(String str) => List<Company>.from(
    json.decode(str)["companies"].map((x) => Company.fromJson(x)));
String companiesToJson(List<Company> data) =>
    '{"companies":' +
    json.encode(List<dynamic>.from(data.map((x) => x.toJson()))) +
    "}";

class Company {
  String partyId;
  String name;
  String classificationId;
  String classificationDescr;
  String email;
  dynamic currencyId;
  Uint8List image;
  String address1;
  String address2;
  String city;
  String postalCode;
  String country;
  ItemTypes itemTypes; // for order and invoiceitem

  Company({
    this.partyId,
    this.name,
    this.classificationId,
    this.classificationDescr,
    this.email,
    this.currencyId,
    this.image,
    this.address1,
    this.address2,
    this.city,
    this.postalCode,
    this.country,
    this.itemTypes,
  });

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        partyId: json["partyId"],
        name: json["name"],
        classificationId: json["classificationId"],
        classificationDescr: json["classificationDescr"],
        email: json["email"],
        currencyId: json["currencyId"],
        image: json["image"] == null || json["image"] == "null"
            ? null
            : base64.decode(json["image"]),
        address1: json["address1"],
        address2: json["address2"],
        city: json["city"],
        postalCode: json["postalCode"],
        country: json["country"],
        itemTypes: json["itemTypes"] == null
            ? null
            : ItemTypes.fromJson(json["itemTypes"]),
      );

  Map<String, dynamic> toJson() => {
        "partyId": partyId,
        "name": name,
        "classificationId": classificationId,
        "classificationDescr": classificationDescr,
        "email": email,
        "currencyId": currencyId,
        "image": image != null ? base64.encode(image) : null,
        "address1": address1,
        "address2": address2,
        "city": city,
        "postalCode": postalCode,
        "country": country,
        "itemTypes": itemTypes == null ? null : itemTypes.toJson()
      };

  String toString() => 'Company name: $name[$partyId] Curr: $currencyId '
      'imgSize: ${image?.length}';
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

  List<ItemType> sales;
  List<ItemType> purchase;

  factory ItemTypes.fromJson(Map<String, dynamic> json) => ItemTypes(
        sales:
            List<ItemType>.from(json["sales"].map((x) => ItemType.fromJson(x))),
        purchase: List<ItemType>.from(
            json["purchase"].map((x) => ItemType.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "sales": List<dynamic>.from(sales.map((x) => x.toJson())),
        "purchase": List<dynamic>.from(purchase.map((x) => x.toJson())),
      };
}

class ItemType {
  ItemType({
    this.itemTypeId,
    this.description,
  });

  String itemTypeId;
  String description;

  factory ItemType.fromJson(Map<String, dynamic> json) => ItemType(
        itemTypeId: json["itemTypeId"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
        "itemTypeId": itemTypeId,
        "description": description,
      };
}
