/*
 * This software is in the public domain under CC0 1.0 Universal plus a
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

// https://stackoverflow.com/a/63073876/2235274
// https://stackoverflow.com/questions/53674027/is-there-a-way-to-fake-datetime-now-in-a-flutter-test/63073876#63073876

// to modify the time, add one day:
//  CustomizableDateTime.customTime =
//      DateTime.now().add(const Duration(days: 1));

import 'package:universal_io/io.dart';

import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'domains/authenticate/views/login_dialog.dart';

extension CustomizableDateTime on DateTime {
  static DateTime? _customTime;
  static DateTime get current {
    return _customTime ?? DateTime.now();
  }

  static set customTime(DateTime customTime) {
    _customTime = customTime;
  }
}

/// Set a days offset for testing time-dependent features.
/// This affects both frontend date (CustomizableDateTime) and backend date
/// (applied during login for subscription checks, etc.).
///
/// Set [daysOffset] to 0 for normal operation, or e.g., 15 to test
/// what happens 15 days in the future (subscription expiration, rentals, etc.).
///
/// Example usage in main.dart:
/// ```dart
/// setTestDaysOffset(15); // Test 15 days in the future
/// ```
void setTestDaysOffset(int daysOffset) {
  CustomizableDateTime.customTime = DateTime.now().add(
    Duration(days: daysOffset),
  );
  LoginDialog.testDaysOffset = daysOffset == 0 ? null : daysOffset;
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

extension StringTruncation on String? {
  String truncate(int strLength) {
    if (this == null) return '';
    if (this!.length > strLength) {
      return '${this!.substring(0, strLength)}...';
    }
    return this ?? '';
  }
}

extension DateOnlyCompare on DateTime {
  bool isSameDate(DateTime other) {
    return day == other.day && month == other.month && year == other.year;
  }
}

extension DateOnly on DateTime? {
  /// Get date-only string in yyyy-MM-dd format
  ///
  /// **Note**: This method uses Gregorian calendar only.
  /// For locale-aware formatting with Buddhist Era support for Thai,
  /// use `toLocalizedDateOnly(context)` from date_format_extensions.dart
  String dateOnly() {
    if (this == null) return '';
    // Always format in local time for display
    DateTime localDate = this!.toLocal();
    return DateFormat('yyyy-MM-dd').format(localDate);
  }
}

extension Noon on DateTime? {
  DateTime noon() {
    // Always format in local time for display
    DateTime localDate = this!.toLocal();
    return DateTime(localDate.year, localDate.month, localDate.day, 12, 0, 0);
  }
}

extension DateTimeUtc on DateTime {
  /// Convert to UTC for server communication
  DateTime toServerTime() => toUtc();

  /// Convert from server time (assumed UTC) to local time
  static DateTime fromServerTime(String serverTimeString) {
    try {
      DateTime utcTime = DateTime.parse(
        serverTimeString +
            (serverTimeString.contains('Z') ||
                    serverTimeString.contains('+') ||
                    serverTimeString.contains('-', 10)
                ? ''
                : 'Z'),
      );
      return utcTime.toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }
}

extension DateTimeSafeParser on String {
  /// Safely parse a date string from server, assuming UTC if no timezone info
  DateTime? toDateTimeSafe() {
    try {
      if (isEmpty) return null;

      // If no timezone info, append 'Z' to indicate UTC
      String timeString = this;
      if (!contains('Z') && !contains('+') && !contains('-', 10)) {
        timeString += 'Z';
      }

      return DateTime.parse(timeString).toLocal();
    } catch (e) {
      return null;
    }
  }
}

/// currency extension to display currencies with a symbol and amount
/// separated US style with ',' and '.'
/// when currency is missing no ',' is displayed to avoid input format problems
extension UsCurrency on Decimal? {
  String currency({String currencyId = "USD"}) {
    if (this == null) return ('');
    var format = NumberFormat.simpleCurrency(
      locale: Platform.localeName,
      name: currencyId,
    );
    String usFormat = currencyId == '' ? "###0.00#" : "#,##0.00#";

    return '${format.currencySymbol}'
        '${NumberFormat(usFormat, "en_US").format(double.parse(toString()))}';
  }
}

extension LastChar on String {
  String lastChar(int length) {
    if (this.length <= length) return this;
    return substring(this.length - length);
  }
}
