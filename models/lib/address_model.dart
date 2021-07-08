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
//      address = addressFromJson(jsonString);

import 'dart:convert';

import 'package:equatable/equatable.dart';

Address addressFromJson(String str) =>
    Address.fromJson(json.decode(str)["address"]);
String addressToJson(Address data) =>
    '{"address":' + json.encode(data.toJson()) + "}";

List<Address> addressesFromJson(String str) => List<Address>.from(
    json.decode(str)["addresses"].map((x) => Address.fromJson(x)));
String addressesToJson(List<Address> data) =>
    '{"addresses":' +
    json.encode(List<dynamic>.from(data.map((x) => x.toJson()))) +
    "}";

class Address extends Equatable {
  final String? addressId; // contactMechId in backend
  final String? address1;
  final String? address2;
  final String? postalCode;
  final String? city;
  final String? province;
  final String? provinceId;
  final String? country;
  final String? countryId;

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

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        addressId: json["addressId"],
        address1: json["address1"],
        address2: json["address2"],
        postalCode: json["postalCode"],
        city: json["city"],
        province: json["province"],
        provinceId: json["provinceId"],
        country: json["country"],
        countryId: json["countryId"],
      );

  Map<String, dynamic> toJson() => {
        "addressId": addressId,
        "address1": address1,
        "address2": address2,
        "postalCode": postalCode,
        "city": city,
        "province": province,
        "provinceId": provinceId,
        "country": country,
        "countryId": countryId,
      };

  @override
  String toString() => 'Address $city $country [$addressId]';

  @override
  List<Object?> get props => [
        addressId, // contactMechId in backend
        address1,
        address2,
        postalCode,
        city,
        province,
        provinceId,
        country,
        countryId,
      ];

  Address copyWith({
    String? addressId, // contactMechId in backend
    String? address1,
    String? address2,
    String? postalCode,
    String? city,
    String? province,
    String? provinceId,
    String? country,
    String? countryd,
  }) =>
      Address(
        addressId: addressId ?? this.addressId,
        address1: address1 ?? this.address1,
        address2: address2 ?? this.address2,
        postalCode: postalCode ?? this.postalCode,
        city: city ?? this.city,
        province: province ?? this.province,
        provinceId: provinceId ?? this.provinceId,
        country: country ?? this.country,
        countryId: countryId ?? this.countryId,
      );
}
