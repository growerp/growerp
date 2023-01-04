import 'dart:convert';
import 'dart:typed_data';
import 'package:growerp_core/domains/domains.dart';
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
    return UserGroup.tryParse(json);
  }

  @override
  String? toJson(UserGroup? object) {
    if (object == null) return null;
    return object.id();
  }
}

class FinDocStatusValConverter
    implements JsonConverter<FinDocStatusVal?, String?> {
  const FinDocStatusValConverter();

  @override
  FinDocStatusVal? fromJson(String? json) {
    if (json == null) return null;
    return FinDocStatusVal.tryParse(json);
  }

  @override
  String? toJson(FinDocStatusVal? object) {
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
    return CreditCardType.tryParse(json);
  }

  @override
  String? toJson(CreditCardType? object) {
    if (object == null) return null;
    return object.toString();
  }
}
