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
    @Uint8ListConverter() Uint8List? image,
    String? name, // either first/last name or company name
    String? email,
    String? telephoneNr,
    Address? address,
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
            type: PartyType.user,
            partyId: obj.partyId,
            pseudoId: obj.pseudoId,
            name: '${obj.lastName}, ${obj.firstName}');
      case Company _:
        return CompanyUser(
            type: PartyType.company,
            partyId: obj.partyId,
            pseudoId: obj.pseudoId,
            name: obj.name);
      default:
        return null;
    }
  }
}

CompanyUser? toCompanyUser(dynamic object) {
  switch (object) {
    case Company():
      return CompanyUser(
          type: PartyType.company,
          partyId: object.partyId,
          pseudoId: object.pseudoId,
          name: object.name,
          role: object.role,
          email: object.email,
          telephoneNr: object.telephoneNr);
    case User():
      if (object.company == null) {
        // return only user when no company
        return CompanyUser(
            type: PartyType.user,
            partyId: object.partyId,
            pseudoId: object.pseudoId,
            name: "${object.lastName}, ${object.firstName}",
            role: object.role,
            email: object.email,
            telephoneNr: object.telephoneNr);
      }
      // if related company return that
      return CompanyUser(
          type: PartyType.company,
          partyId: object.company?.partyId,
          pseudoId: object.company?.pseudoId,
          name: object.company?.name,
          role: object.company?.role,
          email: object.company?.email,
          telephoneNr: object.company?.telephoneNr);
    default:
      return null;
  }
}
