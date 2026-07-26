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

enum UserGroup {
  system('GROWERP_M_SYSTEM'),
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

  static List<UserGroup> getValues() => UserGroup.values
      .where((userGroup) => userGroup != UserGroup.system)
      .toList();
  @override
  String toString() {
    return value;
  }
}
