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

// a replacement for enum:
// https://medium.com/@ra9r/overcoming-the-limitations-of-dart-enum-8866df8a1c47

/// financial document (FinDoc) types
class PaymentInstrument {
  final String _name;
  const PaymentInstrument._(this._name);

  @override
  String toString() {
    return _name;
  }

  static const PaymentInstrument cash = PaymentInstrument._('Cash');
  static const PaymentInstrument creditcard = PaymentInstrument._('CreditCard');
  static const PaymentInstrument bank = PaymentInstrument._('WireTransfer');
  static const PaymentInstrument check = PaymentInstrument._('CompanyCheck');
  static const PaymentInstrument other = PaymentInstrument._('Other');

  static PaymentInstrument tryParse(String val) {
    switch (val.toLowerCase()) {
      case 'cash':
        return cash;
      case 'creditcard':
        return creditcard;
      case 'wiretransfer':
        return bank;
      case 'companycheck':
        return check;
      default:
        return other;
    }
  }
}
