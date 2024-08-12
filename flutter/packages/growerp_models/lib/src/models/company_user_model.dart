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

import 'package:freezed_annotation/freezed_annotation.dart';
import 'models.dart';
import '../json_converters.dart';

part 'company_user_model.freezed.dart';
part 'company_user_model.g.dart';

@freezed
class CompanyUser with _$CompanyUser {
  CompanyUser._();
  factory CompanyUser({
    @PartyTypeConverter() PartyType? type,
    String? partyId,
    String? pseudoId,
    @RoleConverter() Role? role,
    String? name, // either first/last name or company name
    String? email,
    String? telephoneNr,
  }) = _CompanyUser;

  factory CompanyUser.fromJson(Map<String, dynamic> json) =>
      _$CompanyUserFromJson(json["companyUser"] ?? json);

  @override
  String toString() => 'CompanyUser name: $name[$partyId/$pseudoId] ';

  Company? getCompany() => type == PartyType.company
      ? Company(partyId: partyId, pseudoId: pseudoId, name: name)
      : null;

  User? getUser() {
    if (type == PartyType.user) {
      final names = name?.split(', ');
      return User(
          partyId: partyId,
          pseudoId: pseudoId,
          firstName: names != null && names.length > 1 ? names[1] : '',
          lastName: names != null ? names[0] : '');
    }
    return null;
  }

  static CompanyUser? tryParse(dynamic obj) {
    switch (obj) {
      case User _:
        return CompanyUser(
            type: PartyType.company,
            partyId: obj.partyId,
            pseudoId: obj.pseudoId,
            name: '${obj.lastName}, ${obj.firstName}');
      case Company _:
        return CompanyUser(
            type: PartyType.user,
            partyId: obj.partyId,
            pseudoId: obj.pseudoId,
            name: obj.name);
      default:
        return null;
    }
  }
}
