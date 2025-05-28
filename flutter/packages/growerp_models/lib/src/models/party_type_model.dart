/*
 * This GrowERP software is in the public domain under CC0 1.0 Universal plus a
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

enum PartyType {
  company('Company'),
  user('User'),
  unknown('');

  final String value;
  const PartyType(this.value);

  static final Map<String, PartyType> byValue = {};
  static PartyType? getByValue(String value) {
    if (byValue.isEmpty) {
      for (PartyType role in PartyType.values) {
        byValue[role.name] = role;
      }
    }
    return byValue[value];
  }

  static PartyType tryParse(String val) {
    switch (val.toLowerCase()) {
      case 'company':
        return company;
      case 'user':
        return user;
      default:
        return unknown; // default to user if not recognized
    }
  }

  @override
  String toString() {
    return value;
  }
}
