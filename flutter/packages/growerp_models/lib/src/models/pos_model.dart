/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'dart:typed_data';

import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../json_converters.dart';
import 'models.dart';

part 'pos_model.freezed.dart';
part 'pos_model.g.dart';

/// A product the way the till shows it.
@freezed
abstract class PosCatalogItem with _$PosCatalogItem {
  PosCatalogItem._();
  factory PosCatalogItem({
    String? productId,
    String? pseudoId,
    String? productName,
    Decimal? price,
    @Uint8ListConverter() Uint8List? image,
    @Default([]) List<Category> categories,
  }) = _PosCatalogItem;

  factory PosCatalogItem.fromJson(Map<String, dynamic> json) =>
      _$PosCatalogItemFromJson(json['item'] ?? json);
}

/// What the till sells and how its prices are to be read.
@freezed
abstract class PosCatalog with _$PosCatalog {
  PosCatalog._();
  factory PosCatalog({
    @Default([]) List<PosCatalogItem> items,
    @Default([]) List<PosModifierGroup> modifierGroups,
    @Default(false) bool pricesIncludeTax,
    String? currencyId,
  }) = _PosCatalog;

  factory PosCatalog.fromJson(Map<String, dynamic> json) =>
      _$PosCatalogFromJson(json);
}

/// A line sent to the backend: the price is always the one of the catalog.
@freezed
abstract class PosLine with _$PosLine {
  PosLine._();
  factory PosLine({String? productId, Decimal? quantity}) = _PosLine;

  factory PosLine.fromJson(Map<String, dynamic> json) =>
      _$PosLineFromJson(json);
}

@freezed
abstract class PosQuote with _$PosQuote {
  PosQuote._();
  factory PosQuote({Decimal? taxTotal, Decimal? grandTotal}) = _PosQuote;

  factory PosQuote.fromJson(Map<String, dynamic> json) =>
      _$PosQuoteFromJson(json);
}

/// A way the customer pays: method is a payment instrument like PiCash.
@freezed
abstract class PosTender with _$PosTender {
  PosTender._();
  factory PosTender({String? method, Decimal? amount, String? reference}) =
      _PosTender;

  factory PosTender.fromJson(Map<String, dynamic> json) =>
      _$PosTenderFromJson(json);
}

@freezed
abstract class PosSaleLine with _$PosSaleLine {
  PosSaleLine._();
  factory PosSaleLine({
    String? orderItemSeqId,
    String? productId,
    String? description,
    Decimal? quantity,
    Decimal? price,
    Decimal? lineTotal,
    // only from a lookup for a refund
    Decimal? returnableQuantity,
  }) = _PosSaleLine;

  factory PosSaleLine.fromJson(Map<String, dynamic> json) =>
      _$PosSaleLineFromJson(json);
}

@freezed
abstract class PosSaleTax with _$PosSaleTax {
  PosSaleTax._();
  factory PosSaleTax({Decimal? taxPercentage, Decimal? taxAmount}) =
      _PosSaleTax;

  factory PosSaleTax.fromJson(Map<String, dynamic> json) =>
      _$PosSaleTaxFromJson(json);
}

/// A finished sale: what the receipt shows.
@freezed
abstract class PosSale with _$PosSale {
  PosSale._();
  factory PosSale({
    String? clientSaleId,
    String? orderId,
    String? invoiceId,
    String? orderPseudoId,
    String? invoicePseudoId,
    String? terminalName,
    @DateTimeConverter() DateTime? saleDate,
    String? currencyId,
    @Default([]) List<PosSaleLine> lines,
    @Default([]) List<PosSaleTax> taxes,
    Decimal? taxTotal,
    Decimal? grandTotal,
    @Default([]) List<PosTender> tenders,
    Decimal? changeAmount,
  }) = _PosSale;

  factory PosSale.fromJson(Map<String, dynamic> json) =>
      _$PosSaleFromJson(json['sale'] ?? json);
}

/// A line given back: sent with the order item, comes back with a description.
@freezed
abstract class PosRefundLine with _$PosRefundLine {
  PosRefundLine._();
  factory PosRefundLine({
    String? orderItemSeqId,
    String? description,
    Decimal? quantity,
  }) = _PosRefundLine;

  factory PosRefundLine.fromJson(Map<String, dynamic> json) =>
      _$PosRefundLineFromJson(json);
}

/// Money given back for a sale.
@freezed
abstract class PosRefund with _$PosRefund {
  PosRefund._();
  factory PosRefund({
    String? clientRefundId,
    String? clientSaleId,
    String? paymentId,
    String? paymentPseudoId,
    Decimal? amount,
    String? method,
    String? currencyId,
    @Default([]) List<PosRefundLine> lines,
    @DateTimeConverter() DateTime? refundDate,
  }) = _PosRefund;

  factory PosRefund.fromJson(Map<String, dynamic> json) =>
      _$PosRefundFromJson(json['refund'] ?? json);
}

/// The time a till is open. variance is counted minus expected cash.
@freezed
abstract class PosShift with _$PosShift {
  PosShift._();
  factory PosShift({
    String? shiftId,
    String? terminalName,
    String? status,
    Decimal? openingFloat,
    Decimal? expectedCash,
    Decimal? countedCash,
    Decimal? variance,
    @DateTimeConverter() DateTime? openedDate,
    @DateTimeConverter() DateTime? closedDate,
  }) = _PosShift;

  factory PosShift.fromJson(Map<String, dynamic> json) =>
      _$PosShiftFromJson(json['shift'] ?? json);
}

@freezed
abstract class PosShifts with _$PosShifts {
  PosShifts._();
  factory PosShifts({@Default([]) List<PosShift> shifts}) = _PosShifts;

  factory PosShifts.fromJson(Map<String, dynamic> json) =>
      _$PosShiftsFromJson(json);
}

/// What happened in a shift.
@freezed
abstract class PosZReport with _$PosZReport {
  PosZReport._();
  factory PosZReport({
    String? shiftId,
    String? terminalName,
    String? status,
    Decimal? openingFloat,
    Decimal? expectedCash,
    Decimal? countedCash,
    Decimal? variance,
    @DateTimeConverter() DateTime? openedDate,
    @DateTimeConverter() DateTime? closedDate,
    int? saleCount,
    int? voidCount,
    Decimal? salesTotal,
    @Default([]) List<PosTender> tenders,
    int? refundCount,
    Decimal? refundTotal,
    @Default([]) List<PosTender> refundTenders,
    @Default([]) List<PosSaleTax> taxes,
    Decimal? refundTaxTotal,
    Decimal? movementTotal,
  }) = _PosZReport;

  factory PosZReport.fromJson(Map<String, dynamic> json) =>
      _$PosZReportFromJson(json['report'] ?? json);
}

/// A table on the floor plan: status is free, occupied or ready.
@freezed
abstract class PosTable with _$PosTable {
  PosTable._();
  factory PosTable({
    String? assetId,
    String? tableName,
    String? areaName,
    int? x,
    int? y,
    String? shape,
    int? seats,
    String? tabId,
    int? guestCount,
    String? status,
    Decimal? grandTotal,
  }) = _PosTable;

  factory PosTable.fromJson(Map<String, dynamic> json) =>
      _$PosTableFromJson(json['table'] ?? json);
}

@freezed
abstract class PosTables with _$PosTables {
  PosTables._();
  factory PosTables({@Default([]) List<PosTable> tables}) = _PosTables;

  factory PosTables.fromJson(Map<String, dynamic> json) =>
      _$PosTablesFromJson(json);
}

/// A line of a tab: kitchenStatus is New, Sent, Ready, Served or Voided.
@freezed
abstract class PosTabLine with _$PosTabLine {
  PosTabLine._();
  factory PosTabLine({
    String? orderId,
    String? orderItemSeqId,
    String? productId,
    String? description,
    Decimal? quantity,
    Decimal? price,
    String? note,
    String? kitchenStatus,
    int? seatNo,
    int? splitNo,
    String? voidReason,
  }) = _PosTabLine;

  factory PosTabLine.fromJson(Map<String, dynamic> json) =>
      _$PosTabLineFromJson(json);
}

/// The open bill of a table.
@freezed
abstract class PosTab with _$PosTab {
  PosTab._();
  factory PosTab({
    String? tabId,
    String? orderId,
    String? tableAssetId,
    String? tableName,
    int? guestCount,
    String? status,
    String? currencyId,
    @Default([]) List<PosTabLine> lines,
    Decimal? taxTotal,
    Decimal? grandTotal,
  }) = _PosTab;

  factory PosTab.fromJson(Map<String, dynamic> json) =>
      _$PosTabFromJson(json['tab'] ?? json);
}

@freezed
abstract class PosModifier with _$PosModifier {
  PosModifier._();
  factory PosModifier({
    String? modifierId,
    String? modifierName,
    Decimal? priceDelta,
  }) = _PosModifier;

  factory PosModifier.fromJson(Map<String, dynamic> json) =>
      _$PosModifierFromJson(json);
}

/// A choice on products, like the sauce.
@freezed
abstract class PosModifierGroup with _$PosModifierGroup {
  PosModifierGroup._();
  factory PosModifierGroup({
    String? groupId,
    String? groupName,
    int? minSelect,
    int? maxSelect,
    @Default([]) List<PosModifier> modifiers,
    @Default([]) List<String> productIds,
  }) = _PosModifierGroup;

  factory PosModifierGroup.fromJson(Map<String, dynamic> json) =>
      _$PosModifierGroupFromJson(json['group'] ?? json);
}

@freezed
abstract class PosModifierGroups with _$PosModifierGroups {
  PosModifierGroups._();
  factory PosModifierGroups({
    @Default([]) List<PosModifierGroup> modifierGroups,
  }) = _PosModifierGroups;

  factory PosModifierGroups.fromJson(Map<String, dynamic> json) =>
      _$PosModifierGroupsFromJson(json);
}

/// What one send of a tab brought to the kitchen.
@freezed
abstract class PosTicket with _$PosTicket {
  PosTicket._();
  factory PosTicket({
    String? ticketId,
    String? tabId,
    String? tableName,
    @DateTimeConverter() DateTime? sentDate,
    @Default([]) List<PosTabLine> lines,
  }) = _PosTicket;

  factory PosTicket.fromJson(Map<String, dynamic> json) =>
      _$PosTicketFromJson(json);
}

@freezed
abstract class PosTickets with _$PosTickets {
  PosTickets._();
  factory PosTickets({@Default([]) List<PosTicket> tickets}) = _PosTickets;

  factory PosTickets.fromJson(Map<String, dynamic> json) =>
      _$PosTicketsFromJson(json);
}

/// A share of a split bill.
@freezed
abstract class PosShare with _$PosShare {
  PosShare._();
  factory PosShare({int? splitNo, Decimal? amount}) = _PosShare;

  factory PosShare.fromJson(Map<String, dynamic> json) =>
      _$PosShareFromJson(json);
}

@freezed
abstract class PosShares with _$PosShares {
  PosShares._();
  factory PosShares({@Default([]) List<PosShare> shares}) = _PosShares;

  factory PosShares.fromJson(Map<String, dynamic> json) =>
      _$PosSharesFromJson(json);
}

/// Which share a line goes on.
@freezed
abstract class PosSplitAssignment with _$PosSplitAssignment {
  PosSplitAssignment._();
  factory PosSplitAssignment({String? orderItemSeqId, int? splitNo}) =
      _PosSplitAssignment;

  factory PosSplitAssignment.fromJson(Map<String, dynamic> json) =>
      _$PosSplitAssignmentFromJson(json);
}
