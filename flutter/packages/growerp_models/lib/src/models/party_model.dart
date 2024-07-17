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
import 'package:decimal/decimal.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'models.dart';
import '../json_converters.dart';

part 'party_model.freezed.dart';
part 'party_model.g.dart';

@freezed

/// experimental model to replace user and company model
class Party with _$Party {
  factory Party({
    // ==== key data
    String? partyId, // allocated by system cannot be changed.
    String? pseudoId,
    // ==== user data, when company name not null, userdata is not valid
    String? userId, // allocated by system cannot be changed.
    String? firstName,
    String? lastName,

    /// login account is required if disabled just dummy
    bool? loginDisabled,
    String? loginName,

    /// admin, employee, customer, supplier etc...
    // ignore: invalid_annotation_target
    @JsonKey(name: 'userGroupId') @UserGroupConverter() UserGroup? userGroup,
    Party? company, // related company the person is working for
    // ==== company data
    String? companyName, // when not null party is company else party is person
    Decimal? vatPerc,
    Decimal? salesPerc,
    // ==== general data
    String? email,
    String? telephoneNr,
    // the localization variables
    @Default('EN') String language,
    @Default('THB') String currency,
    @Default('GMT') String timeZone,
    @Uint8ListConverter() Uint8List? image,
  }) = _Party;
  Party._();

  factory Party.fromJson(Map<String, dynamic> json) =>
      _$PartyFromJson(json['party'] ?? json);

  @override
  String toString() {
    if (companyName == null) {
      return 'User $firstName $lastName [$partyId] sec: $userGroup  email: $email';
    }
    return 'Company $companyName email: $email';
  }
}
