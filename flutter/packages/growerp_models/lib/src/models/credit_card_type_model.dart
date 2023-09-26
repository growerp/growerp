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

enum CreditCardType {
  amex('American Express'),
  discover('Discover'),
  mc('Master Card'),
  visa('Visa'),
  unknown('');

  final String value;
  const CreditCardType(this.value);

  static final Map<String, CreditCardType> byValue = {};
  static CreditCardType? getByValue(String value) {
    if (byValue.isEmpty) {
      for (CreditCardType creditCardType in CreditCardType.values) {
        byValue[creditCardType.value] = creditCardType;
      }
    }
    return byValue[value];
  }

  @override
  String toString() {
    return value;
  }
}
