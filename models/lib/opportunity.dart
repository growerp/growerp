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
//      opportunity = opportunityFromJson(jsonString);

import 'dart:convert';
import 'package:decimal/decimal.dart';

Opportunity opportunityFromJson(String str) =>
    Opportunity.fromJson(json.decode(str)["opportunity"]);
String opportunityToJson(Opportunity data) =>
    '{"opportunity":' + json.encode(data.toJson()) + "}";

List<Opportunity> opportunitiesFromJson(String str) => List<Opportunity>.from(
    json.decode(str)["opportunities"].map((x) => Opportunity.fromJson(x)));
String opportunitiesToJson(List<Opportunity> data) =>
    '{"opportunities":' +
    json.encode(List<dynamic>.from(data.map((x) => x.toJson()))) +
    "}";

class Opportunity {
  DateTime lastUpdated;
  String opportunityId;
  String opportunityName;
  String description;
  Decimal estAmount;
  int estProbability;
  String stageId;
  String nextStep;
  String accountPartyId;
  String leadPartyId;
  String email;
  String fullName;

  Opportunity({
    this.lastUpdated,
    this.opportunityId,
    this.opportunityName,
    this.description,
    this.estAmount,
    this.estProbability,
    this.stageId,
    this.nextStep,
    this.accountPartyId,
    this.leadPartyId,
    this.email,
    this.fullName,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) => Opportunity(
        lastUpdated: DateTime.tryParse(json["lastUpdated"] ?? ''),
        opportunityId: json["opportunityId"],
        opportunityName: json["opportunityName"],
        description: json["description"],
        estAmount: Decimal.parse(json["estAmount"]),
        estProbability: int.parse(json["estProbability"]),
        stageId: json["stageId"],
        nextStep: json["nextStep"],
        accountPartyId: json["accountPartyId"],
        leadPartyId: json["leadPartyId"],
        fullName: json["fullName"],
        email: json["email"],
      );

  Map<String, dynamic> toJson() => {
        "lastUpdated": lastUpdated.toString(),
        "opportunityId": opportunityId,
        "opportunityName": opportunityName,
        "description": description,
        "estAmount": estAmount.toString(),
        "estProbability": estProbability.toString(),
        "stageId": stageId,
        "nextStep": nextStep,
        "accountPartyId": accountPartyId,
        "leadPartyId": leadPartyId,
        "email": email,
        "fullName": fullName,
      };

  String toString() => 'Opportunity name: $opportunityName[$opportunityId]';
}

List<String> opportunityStages = [
  'Prospecting',
  'Qualification',
  'Demo/Meeting',
  'Proposal',
  'Quote',
];
