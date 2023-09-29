/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

import '../../growerp_models.dart';

/// financial document (FinDoc) types
enum FinDocType {
  order('Order'),
  invoice('Invoice'),
  payment('Payment'),
  shipment('Shipment'),
  transaction('Transaction'),
  unknown('UnKnown');

  const FinDocType(this._name);
  final String _name;

  static FinDocType tryParse(String val) {
    switch (val) {
      case 'Order':
        return order;
      case 'Invoice':
        return invoice;
      case 'Payment':
        return payment;
      case 'Shipment':
        return shipment;
      case 'Transaction':
        return transaction;
    }
    return unknown;
  }

  static String translated(context, FinDocType val) {
    switch (val) {
      case FinDocType.order:
        return ModelLocalizations.of(context)!.order;
      case FinDocType.invoice:
        return ModelLocalizations.of(context)!.invoice;
      case FinDocType.payment:
        return ModelLocalizations.of(context)!.payment;
      case FinDocType.shipment:
        return ModelLocalizations.of(context)!.shipment;
      case FinDocType.transaction:
        return ModelLocalizations.of(context)!.transaction;
      default:
        return ModelLocalizations.of(context)!.unknown;
    }
  }

  @override
  String toString() {
    return _name;
  }
}
