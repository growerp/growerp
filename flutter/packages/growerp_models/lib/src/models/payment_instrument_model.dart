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
