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
class CreditCardType {
  final String _name;
  const CreditCardType._(this._name);

  @override
  String toString() {
    return _name;
  }

  List<String> toList() {
    return ([
      amex.toString(),
      discover.toString(),
      mc.toString(),
      visa.toString(),
      '',
    ]);
  }

  static const CreditCardType amex = CreditCardType._('American Express');
  static const CreditCardType discover = CreditCardType._('Discover');
  static const CreditCardType mc = CreditCardType._('Master Card');
  static const CreditCardType visa = CreditCardType._('Visa');
  static const CreditCardType unknown = CreditCardType._('');

  static CreditCardType tryParse(String val) {
    switch (val) {
      case 'American Express':
        return amex;
      case 'Discover':
        return discover;
      case 'Master Card':
        return mc;
      case 'Visa':
        return visa;
      default:
        return unknown;
    }
  }
}
