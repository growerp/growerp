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
