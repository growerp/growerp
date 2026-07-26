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
