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
//      user = userFromJson(jsonString);

import 'dart:convert';
import 'dart:typed_data';

User userFromJson(String str) => User.fromJson(json.decode(str)["user"]);
String userToJson(User data) => '{"user":' + json.encode(data.toJson()) + "}";

List<User> usersFromJson(String str) =>
    List<User>.from(json.decode(str)["users"].map((x) => User.fromJson(x)));
String usersToJson(List<User> data) =>
    '{"users":' +
    json.encode(List<dynamic>.from(data.map((x) => x.toJson()))) +
    "}";

class User {
  String partyId;
  String userId;
  String firstName;
  String lastName;
  String name;
  String email;
  String groupDescription; // admin, employee, customer, supplier etc...
  String userGroupId;
  String language;
  String country;
  String externalId; // when customer register they give their telno
  Uint8List image;
  String base64Upload; // to upload images to the

  User({
    this.partyId,
    this.userId,
    this.firstName,
    this.lastName,
    this.name,
    this.email,
    this.groupDescription,
    this.userGroupId,
    this.language,
    this.country,
    this.externalId,
    this.image,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        partyId: json["partyId"],
        userId: json["userId"],
        firstName: json["firstName"],
        lastName: json["lastName"],
        name: json["name"],
        email: json["email"],
        groupDescription: json["groupDescription"],
        userGroupId: json["userGroupId"],
        language: json["language"],
        country: json["country"],
        externalId: json["externalId"],
        image: json["image"] == null || json["image"] == "null"
            ? null
            : base64.decode(json["image"]),
      );

  Map<String, dynamic> toJson() => {
        "partyId": partyId ?? null,
        "userId": userId,
        "firstName": firstName,
        "lastName": lastName,
        "name": name,
        "email": email,
        "groupDescription": groupDescription,
        "userGroupId": userGroupId,
        "language": language,
        "country": country,
        "externalId": externalId,
        "image": image != null ? base64.encode(image) : null,
      };

  @override
  String toString() {
    return 'User $firstName $lastName [$partyId] sec: $userGroupId img size: '
        '${image?.length}';
  }
}
