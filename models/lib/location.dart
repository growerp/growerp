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
//      location = locationFromJson(jsonString);

import 'dart:convert';
import 'dart:typed_data';

Location locationFromJson(String str) =>
    Location.fromJson(json.decode(str)["location"]);
String locationToJson(Location data) =>
    '{"location":' + json.encode(data.toJson()) + "}";

List<Location> locationsFromJson(String str) => List<Location>.from(
    json.decode(str)["locations"].map((x) => Location.fromJson(x)));
String locationsToJson(List<Location> data) =>
    '{"locations":' +
    json.encode(List<dynamic>.from(data.map((x) => x.toJson()))) +
    "}";

class Location {
  String locationId;
  String locationTypeId;
  String locationName;
  String description;
  String parentLocationId;
  Uint8List image;

  Location({
    this.locationId,
    this.locationTypeId,
    this.locationName,
    this.description,
    this.parentLocationId,
    this.image,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        locationId: json["locationId"],
        locationTypeId: json["locationTypeId"],
        locationName: json["locationName"],
        description: json["description"],
        parentLocationId: json["parentLocationId"],
        image: json["image"] != null ? base64.decode(json["image"]) : null,
      );

  Map<String, dynamic> toJson() => {
        "locationId": locationId,
        "locationTypeId": locationTypeId,
        "locationName": locationName,
        "description": description,
        "parentLocationId": parentLocationId,
        "image": image != null ? base64.encode(image) : null,
      };

  String toString() => 'Location name: $locationName[$locationId]';

  List<String> locationTypes = [
    'Room',
    'Table',
    'TableArea',
    'WareHouse',
    'Shop',
    'Prepare'
  ];
}
