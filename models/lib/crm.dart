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
//     final crm = crmFromJson(jsonString);

import 'dart:convert';
import 'user.dart';
import 'opportunity.dart';

Crm crmFromJson(String str) => Crm.fromJson(json.decode(str)["crm"]);

String crmToJson(Crm data) => '{"crm":' + json.encode(data.toJson()) + "}";

class Crm {
  List<User> leads;
  List<User> customers;
  List<Opportunity> opportunities;

  Crm({this.leads, this.customers, this.opportunities});

  factory Crm.fromJson(Map<String, dynamic> json) => Crm(
        leads: List<User>.from(json["leads"].map((x) => User.fromJson(x))),
        customers:
            List<User>.from(json["customers"].map((x) => User.fromJson(x))),
        opportunities: List<Opportunity>.from(
            json["opportunities"].map((x) => Opportunity.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "leads": List<dynamic>.from(leads.map((x) => x.toJson())),
        "customers": List<dynamic>.from(customers.map((x) => x.toJson())),
        "opportunities":
            List<dynamic>.from(opportunities.map((x) => x.toJson())),
      };
  @override
  String toString() => 'Crm  leads: ${leads?.length} '
      'Customers: ${customers?.length} '
      'Opportunities: ${opportunities?.length}';
}
