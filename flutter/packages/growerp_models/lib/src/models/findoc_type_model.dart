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

/// financial document (FinDoc) types
enum FinDocType {
  request('Request'),
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
      case 'Request':
        return request;
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

  @override
  String toString() {
    return _name;
  }
}
