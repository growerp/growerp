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

import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_model.freezed.dart';
part 'address_model.g.dart';

@freezed
abstract class Address with _$Address {
  Address._();
  factory Address({
    String? addressId, // contactMechId in backend
    String? address1,
    String? address2,
    String? postalCode,
    String? city,
    String? province,
    String? provinceId,
    String? country,
    String? countryId,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json['address'] ?? json);

  @override
  String toString() =>
      "$address1,${address2 ?? ''},$province,$postalCode $city,$country";
}
