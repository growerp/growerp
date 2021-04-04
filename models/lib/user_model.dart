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
import 'package:equatable/equatable.dart';

import 'address_model.dart';

User userFromJson(String str) => User.fromJson(json.decode(str)["user"]);
String userToJson(User data) => '{"user":' + json.encode(data.toJson()) + "}";

List<User> usersFromJson(String str) =>
    List<User>.from(json.decode(str)["users"].map((x) => User.fromJson(x)));
String usersToJson(List<User> data) =>
    '{"users":' +
    json.encode(List<dynamic>.from(data.map((x) => x.toJson()))) +
    "}";

class User extends Equatable {
  final String? partyId;
  final String? userId;
  final String? firstName;
  final String? lastName;
  final String? name;
  final String? email;
  final String? groupDescription; // admin, employee, customer, supplier etc...
  final String? userGroupId;
  final String? language;
  final String? externalId; // when customer register they give their telno
  final Uint8List? image;
  final String? companyPartyId;
  final String? companyName;
  final Address? address;

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
    this.externalId,
    this.image,
    this.companyPartyId,
    this.companyName,
    this.address,
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
        externalId: json["externalId"],
        image: json["image"] == null ? null : base64.decode(json["image"]),
        companyPartyId: json["companyPartyId"],
        companyName: json["companyName"],
        address:
            json["address"] == null ? null : Address.fromJson(json["address"]),
      );

  Map<String, dynamic> toJson() => {
        "partyId": partyId,
        "userId": userId,
        "firstName": firstName,
        "lastName": lastName,
        "name": name,
        "email": email,
        "groupDescription": groupDescription,
        "userGroupId": userGroupId,
        "language": language,
        "externalId": externalId,
        "image": image != null ? base64.encode(image!) : null,
        "companyPartyId": companyPartyId,
        "companyName": companyName,
        "address": address == null ? null : address!.toJson(),
      };

  @override
  List<Object?> get props => [
        partyId,
        userId,
        firstName,
        lastName,
        name,
        email,
        groupDescription,
        userGroupId,
        language,
        externalId,
        image,
        companyPartyId,
        companyName,
        address,
      ];
  @override
  String toString() {
    return 'User $firstName $lastName [$partyId] sec: $userGroupId '
        'company: $companyName[$companyPartyId] size: ${image?.length}';
  }

  User copyWith({
    String? partyId,
    String? userId,
    String? firstName,
    String? lastName,
    String? name,
    String? email,
    String? groupDescription,
    String? userGroupId,
    String? language,
    String? externalId,
    Uint8List? image,
    String? companyPartyId,
    String? companyName,
    Address? address,
  }) =>
      User(
        partyId: partyId ?? this.partyId,
        userId: userId ?? this.userId,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        name: name ?? this.name,
        email: email ?? this.email,
        groupDescription: groupDescription ?? this.groupDescription,
        userGroupId: userGroupId ?? this.userGroupId,
        language: language ?? this.language,
        externalId: externalId ?? this.externalId,
        image: image ?? this.image,
        companyPartyId: companyPartyId ?? this.companyPartyId,
        companyName: companyName ?? this.companyName,
        address: address ?? this.address,
      );
}

class UserGroup {
  String? userGroupId;
  String? description;

  UserGroup({
    this.userGroupId,
    this.description,
  });
}

List<UserGroup> userGroups = [
  UserGroup(userGroupId: 'GROWERP_M_ADMIN', description: 'Admin'),
  UserGroup(userGroupId: 'GROWERP_M_CUSTOMER', description: 'Customer'),
  UserGroup(userGroupId: 'GROWERP_M_EMPLOYEE', description: 'Employee'),
  UserGroup(userGroupId: 'GROWERP_M_LEAD', description: 'Lead'),
  UserGroup(userGroupId: 'GROWERP_M_SUPPLIER', description: 'Supplier')
];
