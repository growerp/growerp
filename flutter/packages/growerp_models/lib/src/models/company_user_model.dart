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
    String? url,
    String? telephoneNr,
    Address? address,
    PaymentMethod? paymentMethod,
    Company? company, // related company if type == user
  }) = _CompanyUser;

  factory CompanyUser.fromJson(Map<String, dynamic> json) =>
      _$CompanyUserFromJson(json["companyUser"] ?? json);

  @override
  String toString() => 'CompanyUser name: $name[$partyId/$pseudoId] ';

  Company? getCompany() => type == PartyType.company
      ? Company(
          partyId: partyId,
          pseudoId: pseudoId,
          name: name,
          email: email,
          url: url,
          telephoneNr: telephoneNr,
          image: image,
          paymentMethod: paymentMethod,
          address: address,
          role: role)
      : null;

  User? getUser() {
    if (type == PartyType.user) {
      final names = name?.split(', ');
      return User(
          partyId: partyId,
          pseudoId: pseudoId,
          role: role,
          firstName: names != null && names.length > 1 ? names[1] : '',
          lastName: names != null ? names[0] : '',
          address: address,
          email: email,
          url: url,
          telephoneNr: telephoneNr,
          image: image,
          paymentMethod: paymentMethod,
          company: company);
    }
    return null;
  }

  static CompanyUser? tryParse(dynamic obj) {
    switch (obj) {
      case User _:
        if (obj.company == null) {
          return CompanyUser(
              type: PartyType.user,
              partyId: obj.partyId,
              pseudoId: obj.pseudoId,
              name: '${obj.firstName} ${obj.lastName}',
              email: obj.email,
              url: obj.url,
              telephoneNr: obj.telephoneNr,
              image: obj.image,
              paymentMethod: obj.paymentMethod,
              address: obj.address);
        } else {
          return CompanyUser(
              type: PartyType.company,
              partyId: obj.company?.partyId,
              pseudoId: obj.company?.pseudoId,
              name: obj.company?.name,
              email: obj.company?.email,
              url: obj.company?.url,
              telephoneNr: obj.company?.telephoneNr,
              image: obj.company?.image,
              paymentMethod: obj.company?.paymentMethod,
              address: obj.company?.address);
        }
      case Company _:
        return CompanyUser(
            type: PartyType.company,
            partyId: obj.partyId,
            pseudoId: obj.pseudoId,
            name: obj.name,
            email: obj.email,
            url: obj.url,
            telephoneNr: obj.telephoneNr,
            image: obj.image,
            paymentMethod: obj.paymentMethod,
            address: obj.address);
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
          url: object.url,
          image: object.image,
          paymentMethod: object.paymentMethod,
          address: object.address,
          telephoneNr: object.telephoneNr);
    case User():
      if (object.company == null) {
        // return only user when no company
        return CompanyUser(
            type: PartyType.user,
            partyId: object.partyId,
            pseudoId: object.pseudoId,
            name: "${object.firstName} ${object.lastName}",
            role: object.role,
            email: object.email,
            url: object.url,
            image: object.image,
            paymentMethod: object.paymentMethod,
            address: object.address,
            company: object.company,
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
          url: object.company?.url,
          image: object.company?.image,
          paymentMethod: object.company?.paymentMethod,
          address: object.company?.address,
          telephoneNr: object.company?.telephoneNr);
    default:
      return null;
  }
}
