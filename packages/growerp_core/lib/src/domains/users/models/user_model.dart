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
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../services/json_converters.dart';
import '../../domains.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class User with _$User {
  factory User({
    String? partyId, // allocated by system cannot be changed.
    String? userId, // allocated by system cannot be changed.
    String? firstName,
    String? lastName,

    /// login account is required if disabled just dummy
    bool? loginDisabled,
    String? loginName,

    /// email address of this person
    String? email,

    /// when customer register they can give their telephonenr to use as membername
    String? telephoneNr,

    /// admin, employee, customer, supplier etc...
    // ignore: invalid_annotation_target
    @JsonKey(name: 'userGroupId') @UserGroupConverter() UserGroup? userGroup,
    String? language,
    @Uint8ListConverter() Uint8List? image,
    String? companyPartyId, // allocated by system cannot be changed.
    String? companyName,
    String? companyRole,
    Address? companyAddress,
    PaymentMethod? companyPaymentMethod,
  }) = _User;
  User._();

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  @override
  String toString() => 'User $firstName $lastName [$partyId] sec: $userGroup '
      'company: $companyName[$companyPartyId] size: ${image?.length}';
}
