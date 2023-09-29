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

import 'package:json_annotation/json_annotation.dart';

part 'address_model.g.dart';

@JsonSerializable()
class Address {
  String? addressId; // contactMechId in backend
  String? address1;
  String? address2;
  String? postalCode;
  String? city;
  String? province;
  String? provinceId;
  String? country;
  String? countryId;

  Address({
    this.addressId, // contactMechId in backend
    this.address1,
    this.address2,
    this.postalCode,
    this.city,
    this.province,
    this.provinceId,
    this.country,
    this.countryId,
  });

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);
}
