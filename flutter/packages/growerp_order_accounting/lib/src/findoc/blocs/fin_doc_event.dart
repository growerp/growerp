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

part of 'fin_doc_bloc.dart';

abstract class FinDocEvent extends Equatable {
  const FinDocEvent();
  @override
  List<Object> get props => [];
}

class FinDocFetch extends FinDocEvent {
  const FinDocFetch({
    this.finDocId,
    this.pseudoId,
    this.docType,
    this.sales,
    this.customerCompanyPartyId = '',
    this.searchString = '',
    this.refresh = false,
    this.journalId,
    this.limit = 20,
    this.my = false,
    this.status,
  });
  final String searchString;
  final bool refresh;
  final String? finDocId;
  final String? pseudoId;
  final bool? sales;
  final String? journalId;
  final FinDocType? docType; // to get a single document id, docType
  final String customerCompanyPartyId;
  final int limit;
  final bool my; // only show 'my' documents
  final FinDocStatusVal? status; // filter by status

  @override
  List<Object> get props => [
    customerCompanyPartyId,
    searchString,
    refresh,
    finDocId ?? '',
    pseudoId ?? '',
    docType ?? '',
    sales ?? false,
    journalId ?? '',
    limit,
    my,
  ];
}

class FinDocUpdate extends FinDocEvent {
  const FinDocUpdate(this.finDoc);
  final FinDoc finDoc;
  @override
  List<Object> get props => [finDoc];
}

class FinDocShipmentReceive extends FinDocEvent {
  const FinDocShipmentReceive(this.finDoc);
  final FinDoc finDoc;
}

class FinDocConfirmPayment extends FinDocEvent {
  const FinDocConfirmPayment(this.payment);
  final FinDoc payment;
}

class FinDocGetItemTypes extends FinDocEvent {
  const FinDocGetItemTypes({this.searchString, this.sales});
  final String? searchString;
  final bool? sales;
}

class FinDocUpdateItemType extends FinDocEvent {
  const FinDocUpdateItemType({
    required this.itemType,
    this.update,
    this.delete,
  });
  final ItemType itemType;
  final bool? update;
  final bool? delete;
}

class FinDocGetPaymentTypes extends FinDocEvent {
  const FinDocGetPaymentTypes({this.searchString, this.sales});
  final String? searchString;
  final bool? sales;
}

class FinDocUpdatePaymentType extends FinDocEvent {
  const FinDocUpdatePaymentType({
    required this.paymentType,
    this.update,
    this.delete,
  });
  final PaymentType paymentType;
  final bool? update;
  final bool? delete;
}

class FinDocProductRentalDates extends FinDocEvent {
  const FinDocProductRentalDates(this.productId);
  final String? productId;
}

class FinDocGatewayPaymentAuthorize extends FinDocEvent {
  const FinDocGatewayPaymentAuthorize(this.paymentId);
  final String paymentId;
}

class FinDocGatewayPaymentCapture extends FinDocEvent {
  const FinDocGatewayPaymentCapture(this.paymentId);
  final String paymentId;
}

class FinDocGatewayPaymentRelease extends FinDocEvent {
  const FinDocGatewayPaymentRelease(this.paymentId);
  final String paymentId;
}
