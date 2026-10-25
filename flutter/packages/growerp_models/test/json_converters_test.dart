import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_models/growerp_models.dart';

/// Every value of an enum must survive the trip to the backend and back:
/// most converters serialize with toString(), which has to be the value the
/// lookup reads.
void expectRoundTrip<T>(
  String name,
  List<T> values,
  String? Function(T) toJson,
  T? Function(String) fromJson, {
  List<T> skip = const [],
}) {
  for (final value in values.where((v) => !skip.contains(v))) {
    final json = toJson(value);
    expect(json, isNotNull, reason: '$name.$value has no json value');
    expect(fromJson(json!), value, reason: '$name.$value -> "$json"');
  }
}

void main() {
  group('Uint8ListConverter', () {
    const converter = Uint8ListConverter();

    test('Uint8ListConverter_bytes_roundTripsThroughBase64', () {
      // Arrange
      final bytes = Uint8List.fromList([0, 1, 254, 255]);
      // Act
      final json = converter.toJson(bytes);
      // Assert
      expect(json, 'AAH+/w==');
      expect(converter.fromJson(json), bytes);
    });

    test('Uint8ListConverter_null_staysNull', () {
      expect(converter.fromJson(null), isNull);
      expect(converter.toJson(null), isNull);
    });
  });

  group('DateTimeConverter', () {
    const converter = DateTimeConverter();
    final instant = DateTime.utc(2026, 10, 25, 14, 30);

    test('DateTimeConverter_noZoneFromServer_readAsUtcShownLocal', () {
      // Arrange: Moqui sends UTC timestamps without a zone
      const json = '2026-10-25 14:30:00.0';
      // Act
      final result = converter.fromJson(json);
      // Assert
      expect(result!.isUtc, isFalse);
      expect(result.toUtc(), instant);
    });

    test('DateTimeConverter_zuluOrOffset_keepsTheInstant', () {
      expect(converter.fromJson('2026-10-25T14:30:00Z')!.toUtc(), instant);
      expect(converter.fromJson('2026-10-25T21:30:00+07:00')!.toUtc(), instant);
      expect(converter.fromJson('2026-10-25T09:30:00-05:00')!.toUtc(), instant);
    });

    test('DateTimeConverter_toJson_sendsUtcIso8601', () {
      // Arrange
      final local = instant.toLocal();
      // Act
      final json = converter.toJson(local);
      // Assert
      expect(json, '2026-10-25T14:30:00.000Z');
    });

    test('DateTimeConverter_garbageOrNull_returnsNull', () {
      expect(converter.fromJson('not a date'), isNull);
      expect(converter.fromJson(null), isNull);
      expect(converter.toJson(null), isNull);
    });

    test(
      'DateTimeConverter_dateOnly_keepsCalendarDate',
      skip: 'https://github.com/growerp/growerp/issues/46',
      () {
        // Arrange: e.g. Asset.expectedEndOfLifeDate is sent as yyyy-MM-dd
        const json = '2026-10-25';
        // Act
        final result = converter.fromJson(json);
        // Assert
        expect([result?.year, result?.month, result?.day], [2026, 10, 25]);
      },
    );
  });

  group('StringListConverter', () {
    const converter = StringListConverter();

    test('StringListConverter_listOrJsonString_returnsStrings', () {
      expect(converter.fromJson(['a', 1]), ['a', '1']);
      expect(converter.fromJson('["EMAIL","LINKEDIN"]'), ['EMAIL', 'LINKEDIN']);
    });

    test('StringListConverter_plainString_isSingleElementList', () {
      expect(converter.fromJson('EMAIL'), ['EMAIL']);
    });

    test('StringListConverter_toJson_sendsTheList', () {
      expect(converter.toJson(['a', 'b']), ['a', 'b']);
      expect(converter.toJson(null), isNull);
    });
  });

  group('enum converters', () {
    test('UserGroupConverter_everyValue_roundTrips', () {
      const c = UserGroupConverter();
      expectRoundTrip('UserGroup', UserGroup.values, c.toJson, c.fromJson);
    });

    test('RoleConverter_everyValue_roundTrips', () {
      const c = RoleConverter();
      expectRoundTrip('Role', Role.values, c.toJson, c.fromJson);
    });

    test('PartyTypeConverter_everyValue_roundTrips', () {
      const c = PartyTypeConverter();
      expectRoundTrip('PartyType', PartyType.values, c.toJson, c.fromJson);
    });

    test('ActivityTypeConverter_everyValue_roundTrips', () {
      const c = ActivityTypeConverter();
      expectRoundTrip(
        'ActivityType',
        ActivityType.values,
        c.toJson,
        c.fromJson,
      );
    });

    test('LeadStatusConverter_everyValue_roundTrips', () {
      const c = LeadStatusConverter();
      expectRoundTrip('LeadStatus', LeadStatus.values, c.toJson, c.fromJson);
    });

    test('FinDocStatusValConverter_everyValue_roundTrips', () {
      const c = FinDocStatusValConverter();
      expectRoundTrip(
        'FinDocStatusVal',
        FinDocStatusVal.values,
        c.toJson,
        c.fromJson,
      );
    });

    test('WorkOrderStatusValConverter_everyValue_roundTrips', () {
      const c = WorkOrderStatusValConverter();
      expectRoundTrip(
        'WorkOrderStatusVal',
        WorkOrderStatusVal.values,
        c.toJson,
        c.fromJson,
      );
    });

    test('EmployeeStatusConverter_everyValue_roundTrips', () {
      const c = EmployeeStatusConverter();
      expectRoundTrip(
        'EmployeeStatus',
        EmployeeStatus.values,
        c.toJson,
        c.fromJson,
      );
    });

    test('LeaveTypeConverter_everyValue_roundTrips', () {
      const c = LeaveTypeConverter();
      expectRoundTrip('LeaveType', LeaveType.values, c.toJson, c.fromJson);
    });

    test('LeaveStatusConverter_everyValue_roundTrips', () {
      const c = LeaveStatusConverter();
      expectRoundTrip('LeaveStatus', LeaveStatus.values, c.toJson, c.fromJson);
    });

    test('CreditCardTypeConverter_everyValue_roundTrips', () {
      const c = CreditCardTypeConverter();
      expectRoundTrip(
        'CreditCardType',
        CreditCardType.values,
        c.toJson,
        c.fromJson,
      );
    });

    test('PaymentInstrumentConverter_everyValue_roundTrips', () {
      const c = PaymentInstrumentConverter();
      expectRoundTrip(
        'PaymentInstrument',
        [
          PaymentInstrument.cash,
          PaymentInstrument.creditcard,
          PaymentInstrument.bank,
          PaymentInstrument.check,
          PaymentInstrument.other,
        ],
        c.toJson,
        c.fromJson,
      );
    });

    test('PolicyTypeConverter_everyValue_roundTrips', () {
      const c = PolicyTypeConverter();
      expectRoundTrip('PolicyType', PolicyType.values, c.toJson, c.fromJson);
    });

    test('PremiumFrequencyConverter_everyValue_roundTrips', () {
      const c = PremiumFrequencyConverter();
      expectRoundTrip(
        'PremiumFrequency',
        PremiumFrequency.values,
        c.toJson,
        c.fromJson,
      );
    });

    test('PolicyStatusConverter_everyValue_roundTrips', () {
      const c = PolicyStatusConverter();
      expectRoundTrip(
        'PolicyStatus',
        PolicyStatus.values,
        c.toJson,
        c.fromJson,
      );
    });

    test('ClaimStatusConverter_everyValue_roundTrips', () {
      const c = ClaimStatusConverter();
      expectRoundTrip('ClaimStatus', ClaimStatus.values, c.toJson, c.fromJson);
    });

    test('enumConverters_unknownBackendValue_mapsToNull', () {
      expect(const RoleConverter().fromJson('NoSuchRole'), isNull);
      expect(const LeadStatusConverter().fromJson('NoSuchStatus'), isNull);
      expect(const UserGroupConverter().fromJson('NoSuchGroup'), isNull);
    });
  });
}
