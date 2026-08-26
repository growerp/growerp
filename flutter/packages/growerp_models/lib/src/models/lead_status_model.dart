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

/// Status of a lead, backend field name: customerStatus.
/// A party without a status is a new lead, [converted] makes it a customer.
enum LeadStatus {
  assigned('CUSTOMER_ASSIGNED'),
  qualified('CUSTOMER_QUALIFIED'),
  converted('CUSTOMER_CONVERTED');

  final String value;
  const LeadStatus(this.value);

  static LeadStatus? getByValue(String value) {
    for (LeadStatus status in LeadStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }

  @override
  String toString() {
    return value;
  }
}
