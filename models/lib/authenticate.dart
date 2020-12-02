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
import 'user.dart';
import 'company.dart';

Authenticate authenticateFromJson(String str) =>
    Authenticate.fromJson(json.decode(str));

String authenticateToJson(Authenticate data) => json.encode(data.toJson());

class Authenticate {
  String apiKey;
  String moquiSessionToken;
  Company company;
  User user;

  Authenticate({
    this.apiKey,
    this.moquiSessionToken,
    this.company,
    this.user,
  });

  factory Authenticate.fromJson(Map<String, dynamic> json) => Authenticate(
        apiKey: json["apiKey"],
        moquiSessionToken: json["moquiSessionToken"],
        company:
            json["company"] != null ? Company.fromJson(json["company"]) : null,
        user: json["user"] != null ? User.fromJson(json["user"]) : null,
      );

  Map<String, dynamic> toJson() => {
        "apiKey": apiKey,
        "moquiSessionToken": moquiSessionToken,
        "company": company?.toJson(),
        "user": user?.toJson(),
      };
  @override
  String toString() => 'Company: ${company?.toString()} '
      'User: ${user?.toString()} apiKey: '
      '....${apiKey?.substring(apiKey.length - 10)}';
}
