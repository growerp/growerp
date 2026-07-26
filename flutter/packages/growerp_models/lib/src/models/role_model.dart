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

enum Role {
  company('OrgInternal'), // employee of the organization
  customer('Customer'),
  lead('Lead'),
  supplier('Supplier'),
  unknown('');

  final String value;
  const Role(this.value);

  static final Map<String, Role> byValue = {};
  static Role? getByValue(String value) {
    if (byValue.isEmpty) {
      for (Role role in Role.values) {
        byValue[role.toString()] = role;
      }
    }
    return byValue[value];
  }

  static Role tryParse(String val) {
    switch (val.toLowerCase()) {
      case 'supplier':
        return supplier;
      case 'customer':
        return customer;
      case 'lead':
        return lead;
      case 'orginternal':
        return company;
      default:
        return unknown;
    }
  }

  @override
  String toString() {
    return value;
  }
}
