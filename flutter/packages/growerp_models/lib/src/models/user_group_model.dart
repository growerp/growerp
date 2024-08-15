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

enum UserGroup {
  employee('GROWERP_M_EMPLOYEE'),
  admin('GROWERP_M_ADMIN'),
  other('GROWERP_M_OTHER');

  final String value;
  const UserGroup(this.value);

  static final Map<String, UserGroup> byValue = {};
  static UserGroup? getByValue(String value) {
    if (byValue.isEmpty) {
      for (UserGroup userGroup in UserGroup.values) {
        byValue[userGroup.value] = userGroup;
      }
    }
    return byValue[value];
  }

  @override
  String toString() {
    return value;
  }
}
