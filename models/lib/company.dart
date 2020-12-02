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
import 'user.dart';

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
  List<User> employees;

  Company(
      {this.partyId,
      this.name,
      this.classificationId,
      this.classificationDescr,
      this.email,
      this.currencyId,
      this.image,
      this.employees});

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
        employees: json["employees"] != null
            ? List<User>.from(json["employees"].map((x) => User.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        "partyId": partyId,
        "name": name,
        "classificationId": classificationId,
        "classificationDescr": classificationDescr,
        "email": email,
        "currencyId": currencyId,
        "image": image != null ? base64.encode(image) : null,
        "employees": employees != null
            ? List<dynamic>.from(employees.map((x) => x.toJson()))
            : null,
      };

  String toString() => 'Company name: $name[$partyId] Curr: $currencyId '
      'empl: ${employees?.length} '
      'imgSize: ${image?.length}';
}
