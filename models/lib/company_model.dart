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

import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'address_model.dart';

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

class Company extends Equatable {
  final String? partyId;
  final String? name;
  final String? classificationId;
  final String? classificationDescr;
  final String? email;
  final String? currencyId;
  final Uint8List? image;
  final Address? address;
  final Decimal? vatPerc;
  final Decimal? salesPerc;

  Company({
    this.partyId,
    this.name,
    this.classificationId,
    this.classificationDescr,
    this.email,
    this.currencyId,
    this.image,
    this.address,
    this.vatPerc,
    this.salesPerc,
  });

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        partyId: json["partyId"],
        name: json["name"],
        classificationId: json["classificationId"],
        classificationDescr: json["classificationDescr"],
        email: json["email"],
        currencyId: json["currencyId"],
        image: json["image"] == null ? null : base64.decode(json["image"]),
        address:
            json["address"] == null ? null : Address.fromJson(json["address"]),
        vatPerc: json["vatPerc"] == null
            ? Decimal.parse("0.00")
            : Decimal.parse(json["vatPerc"]),
        salesPerc: json["salesPerc"] == null
            ? Decimal.parse("0.00")
            : Decimal.parse(json["salesPerc"]),
      );

  Map<String, dynamic> toJson() => {
        "partyId": partyId,
        "name": name,
        "classificationId": classificationId,
        "classificationDescr": classificationDescr,
        "email": email,
        "currencyId": currencyId,
        "image": image != null ? base64.encode(image!) : null,
        "address": address == null ? null : address!.toJson(),
        "vatPerc": vatPerc == null ? null : vatPerc.toString(),
        "salesPerc": salesPerc == null ? null : salesPerc.toString(),
      };
  @override
  List<Object?> get props => [
        partyId,
        name,
        classificationId,
        classificationDescr,
        email,
        currencyId,
        image,
        address,
        vatPerc,
        salesPerc,
      ];

  @override
  String toString() => 'Company name: $name[$partyId] Curr: $currencyId '
      'imgSize: ${image?.length}';

  Company copyWith({
    String? partyId,
    String? name,
    String? classificationId,
    String? classificationDescr,
    String? email,
    String? currencyId,
    Uint8List? image,
    Address? address,
    Decimal? vatPerc,
    Decimal? salesPerc,
  }) =>
      Company(
        partyId: partyId ?? this.partyId,
        name: name ?? this.name,
        classificationId: classificationId ?? this.classificationId,
        classificationDescr: classificationDescr ?? this.classificationDescr,
        email: email ?? this.email,
        currencyId: currencyId ?? this.currencyId,
        image: image ?? this.image,
        address: address ?? this.address,
        vatPerc: vatPerc ?? this.vatPerc,
        salesPerc: salesPerc ?? this.salesPerc,
      );
}
