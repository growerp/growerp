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

import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

part 'stats_model.g.dart';

@JsonSerializable()
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
  int allTasks;
  int notInvoicedHours;
  int incomingShipments;
  int outgoingShipments;
  int whLocations;

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
    this.allTasks = 0,
    this.notInvoicedHours = 0,
    this.incomingShipments = 0,
    this.outgoingShipments = 0,
    this.whLocations = 0,
  });
  factory Stats.fromJson(Map<String, dynamic> json) => _$StatsFromJson(json);
  Map<String, dynamic> toJson() => _$StatsToJson(this);
}
