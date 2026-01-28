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
import 'models/models.dart';
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
    try {
      // Parse the timestamp and ensure it's treated as UTC from server
      DateTime? parsed = DateTime.tryParse(json);
      if (parsed != null) {
        // If the parsed datetime doesn't have timezone info, treat it as UTC
        if (!json.contains('Z') &&
            !json.contains('+') &&
            !json.contains('-', 10)) {
          // Assume server time is UTC and convert to local
          return DateTime.parse('${json}Z').toLocal();
        }
        return parsed.toLocal(); // Convert to local time for display
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  String? toJson(DateTime? object) {
    if (object == null) return null;
    // Always send to server in UTC to avoid timezone issues
    // Include timezone information in the format
    return object.toUtc().toIso8601String();
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
    return object.value;
  }
}

class PartyTypeConverter implements JsonConverter<PartyType?, String?> {
  const PartyTypeConverter();

  @override
  PartyType? fromJson(String? json) {
    if (json == null) return null;
    return PartyType.tryParse(json);
  }

  @override
  String? toJson(PartyType? object) {
    if (object == null) return null;
    return object.value;
  }
}

class ActivityTypeConverter implements JsonConverter<ActivityType?, String?> {
  const ActivityTypeConverter();

  @override
  ActivityType? fromJson(String? json) {
    if (json == null) return null;
    return ActivityType.tryParse(json);
  }

  @override
  String? toJson(ActivityType? object) {
    if (object == null) return null;
    return object.name;
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

/// Converter for handling List<String> that may come as a JSON string or a List
class StringListConverter implements JsonConverter<List<String>?, dynamic> {
  const StringListConverter();

  @override
  List<String>? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is List) {
      return json.map((e) => e.toString()).toList();
    }
    if (json is String) {
      try {
        final decoded = jsonDecode(json);
        if (decoded is List) {
          return decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {
        // If it's not valid JSON, treat as a single-element list
        return [json];
      }
    }
    return null;
  }

  @override
  dynamic toJson(List<String>? object) {
    if (object == null) return null;
    return object;
  }
}
