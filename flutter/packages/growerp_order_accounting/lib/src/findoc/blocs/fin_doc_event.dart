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
    this.finDocId = '',
    this.docType = FinDocType.unknown,
    this.customerCompanyPartyId = '',
    this.searchString = '',
    this.refresh = false,
    this.journalId,
    this.limit = 20,
  });
  final String searchString;
  final bool refresh;
  final String finDocId;
  final String? journalId;
  final FinDocType docType; // to get a single document id, docType
  final String customerCompanyPartyId;
  final int limit;

  @override
  List<Object> get props =>
      [finDocId, docType, customerCompanyPartyId, searchString, refresh];
}

class FinDocItemFetch extends FinDocEvent {
  const FinDocItemFetch({
    required this.finDocId,
    required this.docType,
  });
  final String finDocId;
  final FinDocType docType;
  @override
  List<Object> get props => [finDocId];
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

@Deprecated("You should use the UserBloc")
class FinDocGetUsers extends FinDocEvent {
  const FinDocGetUsers({this.role, this.filter});
  final Role? role;
  final String? filter;
}

class FinDocGetItemTypes extends FinDocEvent {}

class FinDocGetPaymentTypes extends FinDocEvent {
  const FinDocGetPaymentTypes(this.sales);
  final bool sales;
}
