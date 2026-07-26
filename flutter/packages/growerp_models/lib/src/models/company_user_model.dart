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

import 'dart:typed_data';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'models.dart';
import '../json_converters.dart';

part 'company_user_model.freezed.dart';
part 'company_user_model.g.dart';

@freezed
abstract class CompanyUser with _$CompanyUser {
  CompanyUser._();
  factory CompanyUser({
    @PartyTypeConverter() PartyType? type,
    String? partyId,
    String? pseudoId,
    @RoleConverter() Role? role,
    @Uint8ListConverter() Uint8List? image,
    String? name, // either first/last name or company name
    String? personalTitle, // job title / position (e.g. LinkedIn 'Position')
    String? email,
    String? url,
    String? telephoneNr,
    Address? address,
    PaymentMethod? paymentMethod,
    Company? company, // related company if type == user
    List<User>? employees,
  }) = _CompanyUser;

  factory CompanyUser.fromJson(Map<String, dynamic> json) =>
      _$CompanyUserFromJson(json["companyUser"] ?? json);

  @override
  String toString() => 'CompanyUser name: $name[$partyId/$pseudoId] ';

  Company? getCompany() {
    if (type == PartyType.company) {
      return Company(
        role: role,
        partyId: partyId,
        pseudoId: pseudoId,
        name: name,
        email: email,
        url: url,
        telephoneNr: telephoneNr,
        image: image,
        paymentMethod: paymentMethod,
        address: address,
        employees: employees ?? [],
      );
    } else {
      List<String> names = [];
      for (final sep in [', ', ' ,', ' , ', ',', ' ']) {
        int index = name!.indexOf(sep);
        if (index == -1) continue;
        names.add(name!.substring(0, index));
        names.add(name!.substring(index + sep.length));
      }
      if (company != null) {
        return company!.copyWith(
          employees: [
            User(
              role: role,
              partyId: partyId,
              pseudoId: pseudoId,
              firstName: names[0],
              lastName: names[1],
              email: email,
              url: url,
              telephoneNr: telephoneNr,
              image: image,
              paymentMethod: paymentMethod,
              address: address,
            ),
          ],
        );
      } else {
        return Company();
      }
    }
  }

  User? getUser() {
    User user = User();
    if (type == PartyType.user) {
      List<String> names = [];
      for (final sep in [', ', ' ,', ' , ', ',', ' ']) {
        int index = name!.indexOf(sep);
        if (index == -1) continue;
        names.add(name!.substring(0, index));
        names.add(name!.substring(index + sep.length));
      }
      return User(
        partyId: partyId,
        pseudoId: pseudoId,
        role: role,
        firstName: names[0],
        lastName: names[1],
        address: address,
        email: email,
        url: url,
        telephoneNr: telephoneNr,
        image: image,
        paymentMethod: paymentMethod,
        company: company,
      );
    } else {
      if (employees != null && employees!.isNotEmpty) {
        user = User(
          role: employees?.first.role,
          partyId: employees?.first.partyId,
          pseudoId: employees?.first.pseudoId,
          firstName: employees?.first.firstName,
          lastName: employees?.first.lastName,
          address: employees?.first.address,
          email: employees?.first.email,
          url: employees?.first.url,
          telephoneNr: employees?.first.telephoneNr,
          image: employees?.first.image,
          paymentMethod: employees?.first.paymentMethod,
        );
      }
      return user.copyWith(
        company: Company(
          role: role,
          partyId: partyId,
          pseudoId: pseudoId,
          name: name,
          email: email,
          url: url,
          telephoneNr: telephoneNr,
          image: image,
          paymentMethod: paymentMethod,
          address: address,
        ),
      );
    }
  }

  static CompanyUser? tryParse(dynamic obj) {
    switch (obj) {
      case User _:
        return CompanyUser(
          type: PartyType.user,
          role: obj.role,
          partyId: obj.partyId,
          pseudoId: obj.pseudoId,
          name: '${obj.firstName} ${obj.lastName}',
          email: obj.email,
          url: obj.url,
          telephoneNr: obj.telephoneNr,
          image: obj.image,
          paymentMethod: obj.paymentMethod,
          address: obj.address,
          company: obj.company,
        );
      case Company _:
        return CompanyUser(
          type: PartyType.company,
          role: obj.role,
          partyId: obj.partyId,
          pseudoId: obj.pseudoId,
          name: obj.name,
          email: obj.email,
          url: obj.url,
          telephoneNr: obj.telephoneNr,
          image: obj.image,
          paymentMethod: obj.paymentMethod,
          address: obj.address,
          employees: obj.employees,
        );
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
        telephoneNr: object.telephoneNr,
        employees: object.employees,
      );
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
          telephoneNr: object.telephoneNr,
          company: object.company,
        );
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
        telephoneNr: object.company?.telephoneNr,
        employees: object.company?.employees ?? [],
      );
    default:
      return null;
  }
}
