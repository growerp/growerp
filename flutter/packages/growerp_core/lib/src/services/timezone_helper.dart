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

import 'package:intl/intl.dart';

/// Helper class for handling timezone differences between client and server
class TimeZoneHelper {
  /// Convert a local DateTime to UTC for server communication
  static DateTime toServerTime(DateTime localTime) {
    return localTime.toUtc();
  }

  /// Convert a server timestamp (assumed UTC) to local time for display
  static DateTime fromServerTime(String serverTimeString) {
    try {
      // Handle various server time formats
      DateTime utcTime;

      if (serverTimeString.contains('Z') ||
          serverTimeString.contains('+') ||
          serverTimeString.contains('-', 10)) {
        // Already has timezone info
        utcTime = DateTime.parse(serverTimeString);
      } else {
        // Assume UTC and add 'Z'
        utcTime = DateTime.parse('${serverTimeString}Z');
      }

      return utcTime.toLocal();
    } catch (e) {
      // Fallback to current time if parsing fails
      return DateTime.now();
    }
  }

  /// Format a DateTime for display in local timezone
  static String formatLocalDate(
    DateTime? dateTime, {
    String format = 'yyyy/M/d',
  }) {
    if (dateTime == null) return '';
    return DateFormat(format).format(dateTime.toLocal());
  }

  /// Format a DateTime for display with time in local timezone
  static String formatLocalDateTime(
    DateTime? dateTime, {
    String format = 'yyyy/M/d HH:mm',
  }) {
    if (dateTime == null) return '';
    return DateFormat(format).format(dateTime.toLocal());
  }

  /// Get current time in UTC for server communication
  static DateTime nowUtc() {
    return DateTime.now().toUtc();
  }

  /// Check if two dates are the same day in local time
  static bool isSameLocalDate(DateTime? date1, DateTime? date2) {
    if (date1 == null || date2 == null) return false;

    DateTime local1 = date1.toLocal();
    DateTime local2 = date2.toLocal();

    return local1.year == local2.year &&
        local1.month == local2.month &&
        local1.day == local2.day;
  }

  /// Convert a date-only string (YYYY-MM-DD) to DateTime at midnight UTC
  static DateTime? dateStringToUtc(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      // Parse as local date then convert to UTC at midnight
      DateTime localDate = DateTime.parse(dateString);
      return DateTime.utc(localDate.year, localDate.month, localDate.day);
    } catch (e) {
      return null;
    }
  }

  /// Convert a DateTime to date-only string in local timezone
  static String? dateTimeToDateString(DateTime? dateTime) {
    if (dateTime == null) return null;

    DateTime localDate = dateTime.toLocal();
    return DateFormat('yyyy-MM-dd').format(localDate);
  }
}
