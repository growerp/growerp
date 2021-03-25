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
//     final glAccount = glAccountFromJson(jsonString);
//     glAccountList = glAccountListFromJson(jsonString);

import 'dart:convert';

GlAccount glAccountFromJson(String str) => GlAccount.fromJson(json.decode(str));
String glAccountToJson(GlAccount data) => json.encode(data.toJson());

List<GlAccount> glAccountListFromJson(String str) => List<GlAccount>.from(
    json.decode(str)["glAccountList"].map((x) => GlAccount.fromJson(x)));
String glAccountListToJson(List<GlAccount> data) =>
    '{"glAccountList":' +
    json.encode(List<dynamic>.from(data.map((x) => x.toJson()))) +
    "}";

class GlAccount {
  GlAccount({
    this.id,
    this.l, // level
    this.classId,
    this.isDebit,
    this.accountName,
    this.postedBalance,
    this.rollUp,
    this.children,
  });

  String? id;
  int? l;
  String? classId;
  String? isDebit;
  String? accountName;
  double? postedBalance;
  double? rollUp;
  List<GlAccount>? children;

  factory GlAccount.fromJson(Map<String, dynamic> json) => GlAccount(
        id: json["id"],
        l: json["l"],
        classId: json["classId"],
        isDebit: json["isDebit"],
        accountName: json["accountName"],
        postedBalance: json["postedBalance"] != null
            ? json["postedBalance"].toDouble()
            : 0,
        rollUp: json["rollUp"] != null ? json["rollUp"].toDouble() : 0,
        children: List<GlAccount>.from(
            json["children"].map((x) => GlAccount.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "l": l,
        "classId": classId,
        "isDebit": isDebit,
        "accountName": accountName,
        "postedBalance": postedBalance,
        "rollUp": rollUp,
        "children": List<dynamic>.from(children!.map((x) => x.toJson())),
      };
}
