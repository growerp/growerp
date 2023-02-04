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

import 'dart:convert';
import 'dart:typed_data';
import '../domains/domains.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

class Uint8ListConverter implements JsonConverter<Uint8List?, String?> {
  const Uint8ListConverter();

  @override
  Uint8List? fromJson(String? json) {
    if (json == null) return null;
    return base64.decode(json);
  }

  @override
  String? toJson(Uint8List? object) {
    if (object == null) return null;
    return base64.encode(object);
  }
}

class DateTimeConverter implements JsonConverter<DateTime?, String?> {
  const DateTimeConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null) return null;
    return DateTime.tryParse(json);
  }

  @override
  String? toJson(DateTime? object) {
    if (object == null) return null;
    return object.toString();
  }
}

class TimeConverter implements JsonConverter<TimeOfDay?, String?> {
  const TimeConverter();

  @override
  TimeOfDay? fromJson(String? json) {
    if (json == null) return null;
    return TimeOfDay(
        hour: int.parse(json.substring(0, 2)),
        minute: int.parse(json.substring(3, 5)));
  }

  @override
  String? toJson(TimeOfDay? object) {
    if (object == null) return null;
    return object.toString();
  }
}

class FinDocTypeConverter implements JsonConverter<FinDocType?, String?> {
  const FinDocTypeConverter();

  @override
  FinDocType? fromJson(String? json) {
    if (json == null) return null;
    return FinDocType.tryParse(json);
  }

  @override
  String? toJson(FinDocType? object) {
    if (object == null) return null;
    return object.toString();
  }
}

class PaymentInstrumentConverter
    implements JsonConverter<PaymentInstrument?, String?> {
  const PaymentInstrumentConverter();

  @override
  PaymentInstrument? fromJson(String? json) {
    if (json == null) return null;
    return PaymentInstrument.tryParse(json);
  }

  @override
  String? toJson(PaymentInstrument? object) {
    if (object == null) return null;
    return object.toString();
  }
}

class UserGroupConverter implements JsonConverter<UserGroup?, String?> {
  const UserGroupConverter();

  @override
  UserGroup? fromJson(String? json) {
    if (json == null) return null;
    return UserGroup.getByValue(json);
  }

  @override
  String? toJson(UserGroup? object) {
    if (object == null) return null;
    return object.value;
  }
}

class FinDocStatusValConverter
    implements JsonConverter<FinDocStatusVal?, String?> {
  const FinDocStatusValConverter();

  @override
  FinDocStatusVal? fromJson(String? json) {
    if (json == null) return null;
    return FinDocStatusVal.getByValue(json);
  }

  @override
  String? toJson(FinDocStatusVal? object) {
    if (object == null) return null;
    return object.toString();
  }
}

class RoleConverter implements JsonConverter<Role?, String?> {
  const RoleConverter();

  @override
  Role? fromJson(String? json) {
    if (json == null) return null;
    return Role.getByValue(json);
  }

  @override
  String? toJson(Role? object) {
    if (object == null) return null;
    return object.toString();
  }
}

class CreditCardTypeConverter
    implements JsonConverter<CreditCardType?, String?> {
  const CreditCardTypeConverter();

  @override
  CreditCardType? fromJson(String? json) {
    if (json == null) return null;
    return CreditCardType.getByValue(json);
  }

  @override
  String? toJson(CreditCardType? object) {
    if (object == null) return null;
    return object.toString();
  }
}
