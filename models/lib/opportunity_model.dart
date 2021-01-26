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
import 'package:equatable/equatable.dart';

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

class Opportunity extends Equatable {
  final DateTime lastUpdated;
  final String opportunityId;
  final String opportunityName;
  final String description;
  final Decimal estAmount;
  final int estProbability;
  final String stageId;
  final String nextStep;
  final String accountPartyId;
  final String accountEmail;
  final String accountFirstName;
  final String accountLastName;
  final String leadPartyId;
  final String leadEmail;
  final String leadFirstName;
  final String leadLastName;

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
    this.accountEmail,
    this.accountFirstName,
    this.accountLastName,
    this.leadPartyId,
    this.leadEmail,
    this.leadFirstName,
    this.leadLastName,
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
        accountFirstName: json["accountFirstName"],
        accountLastName: json["accountLastName"],
        accountEmail: json["accountEmail"],
        leadPartyId: json["leadPartyId"],
        leadFirstName: json["leadFirstName"],
        leadLastName: json["leadLastName"],
        leadEmail: json["leadEmail"],
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
        "accountFirstName": accountFirstName,
        "accountLastName": accountLastName,
        "accountEmail": accountEmail,
        "leadPartyId": leadPartyId,
        "leadFirstName": leadFirstName,
        "leadLastName": leadLastName,
        "leadEmail": leadEmail,
      };
  @override
  List<Object> get props => [
        lastUpdated,
        opportunityId,
        opportunityName,
        description,
        estAmount,
        estProbability,
        stageId,
        nextStep,
        accountPartyId,
        accountFirstName,
        accountLastName,
        accountEmail,
        leadPartyId,
        leadFirstName,
        leadLastName,
        leadEmail,
      ];
  String toString() => 'Opportunity name: $opportunityName[$opportunityId]';
}

List<String> opportunityStages = [
  'Prospecting',
  'Qualification',
  'Demo/Meeting',
  'Proposal',
  'Quote',
];
