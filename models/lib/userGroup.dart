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

// To parse this JSON data, do
//
//      userGroup = userGroupFromJson(jsonString);

import 'dart:convert';

UserGroup userGroupFromJson(String str) =>
    UserGroup.fromJson(json.decode(str)["userGroup"]);
String userGroupToJson(UserGroup data) =>
    '{"userGroup":' + json.encode(data.toJson()) + "}";

List<UserGroup> userGroupsFromJson(String str) => List<UserGroup>.from(
    json.decode(str)["userGroups"].map((x) => UserGroup.fromJson(x)));
String userGroupsToJson(List<UserGroup> data) =>
    '{"userGroups":' +
    json.encode(List<dynamic>.from(data.map((x) => x.toJson()))) +
    "}";

class UserGroup {
  String userGroupId;
  String description;

  UserGroup({
    this.userGroupId,
    this.description,
  });

  factory UserGroup.fromJson(Map<String, dynamic> json) => UserGroup(
        userGroupId: json["userGroupId"],
        description: json["description"],
      );

  Map<String, dynamic> toJson() => {
        "userGroupId": userGroupId,
        "description": description,
      };

  @override
  String toString() => 'UserGroup name: $description [$userGroupId]';
}

List<UserGroup> userGroups = [
  UserGroup(userGroupId: 'GROWERP_M_ADMIN', description: 'Admin'),
  UserGroup(userGroupId: 'GROWERP_M_CUSTOMER', description: 'Customer'),
  UserGroup(userGroupId: 'GROWERP_M_EMPLOYEE', description: 'Employee')
];
