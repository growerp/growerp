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
import 'package:json_annotation/json_annotation.dart';

import 'models.dart';

part 'company_model.g.dart';

@JsonSerializable()
class Company {
  String? partyId;
  @RoleConverter()
  Role? role;
  String? name;
  String? email;
  String? telephoneNr;
  Currency? currency;
  @Uint8ListConverter()
  Uint8List? image;
  Address? address;
  PaymentMethod? paymentMethod;
  Decimal? vatPerc;
  Decimal? salesPerc;
  List<User> employees;

  Company({
    this.partyId,
    this.role,
    this.name,
    this.email,
    this.telephoneNr,
    this.currency,
    this.image,
    this.address,
    this.paymentMethod,
    this.vatPerc,
    this.salesPerc,
    this.employees = const [],
  });

  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json);
  Map<String, dynamic> toJson() => _$CompanyToJson(this);

  @override
  String toString() => 'Company name: $name[$partyId] '
      'Curr: ${currency?.currencyId} '
      'imgSize: ${image?.length}'
      '#Empl: ${employees.length}';
}
