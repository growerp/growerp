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

import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';

import 'models.dart';

part 'user_model.g.dart';

@JsonSerializable()
class User {
  String? partyId; // allocated by system cannot be changed.
  String? userId; // allocated by system cannot be changed.
  String? firstName;
  String? lastName;

  /// login account is required if disabled just dummy
  bool? loginDisabled;
  String? loginName;

  /// email address of this person
  String? email;

  /// when customer register they can give their telephonenr to use as membername
  String? telephoneNr;

  /// admin, employee, customer, supplier etc...
  // ignore: invalid_annotation_target
  @JsonKey(name: 'userGroupId')
  @UserGroupConverter()
  UserGroup? userGroup;
  // the localization variables
  String language;
  String currency;
  String timeZone;
  @Uint8ListConverter()
  Uint8List? image;
  Company? company;

  User({
    this.partyId, // allocated by system cannot be changed.
    this.userId, // allocated by system cannot be changed.
    this.firstName,
    this.lastName,

    /// login account is required if disabled just dummy
    this.loginDisabled,
    this.loginName,

    /// email address of this person
    this.email,

    /// when customer register they can give their telephonenr to use as membername
    this.telephoneNr,

    /// admin, employee, customer, supplier etc...
    // ignore: invalid_annotation_target
    this.userGroup,
    // the localization variables
    this.language = 'EN',
    this.currency = 'THB',
    this.timeZone = 'GMT',
    this.image,
    this.company,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  @override
  String toString() => 'User $firstName $lastName [$partyId] sec: $userGroup '
      'company: ${company!.name}[${company!.partyId}] size: ${image?.length}';
}
