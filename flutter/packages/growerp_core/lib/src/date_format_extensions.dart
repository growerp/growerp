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

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Extension for locale-aware date formatting with Buddhist Era support
///
/// **When to use:**
/// - Use these methods in UI code where dates are displayed to users
/// - DO NOT use in tests (tests always use Gregorian calendar via dateOnly())
/// - DO NOT use for backend communication (backend always uses Gregorian)
///
/// **How it works:**
/// - When Thai locale (th) is selected, automatically converts years to Buddhist Era (BE)
///   by adding 543 years to the Gregorian year
/// - For all other locales, uses standard Gregorian calendar
/// - Database always stores Gregorian/Western years - conversion only happens for display
///
/// **Example:**
/// ```dart
/// // In UI code:
/// Text(order.createdDate.toLocalizedDateOnly(context))  // Shows BE for Thai users
///
/// // In tests:
/// expect(order.createdDate.dateOnly(), '2025-10-04')  // Always Gregorian
/// ```
extension LocalizedDateFormat on DateTime? {
  /// Format date with locale awareness - supports Buddhist Era for Thai locale
  ///
  /// [context] - BuildContext to access current locale
  /// [format] - Date format pattern (default: 'yyyy-MM-dd')
  ///
  /// Example:
  /// ```dart
  /// Text(order.createdDate.toLocalizedString(context))
  /// Text(event.eventDate.toLocalizedString(context, format: 'dd/MM/yyyy'))
  /// ```
  String toLocalizedString(
    BuildContext context, {
    String format = 'yyyy-MM-dd',
  }) {
    if (this == null) return '';

    final locale = Localizations.localeOf(context);
    final localDate = this!.toLocal();

    // For Thai locale, convert to Buddhist Era
    if (locale.languageCode == 'th') {
      return _formatBuddhistEra(localDate, format);
    }

    // For other locales, use standard formatting
    return DateFormat(format).format(localDate);
  }

  /// Format date-only (no time) with locale awareness
  ///
  /// Uses 'yyyy-MM-dd' format for non-Thai locales
  /// Uses Buddhist Era for Thai locale
  String toLocalizedDateOnly(BuildContext context) {
    return toLocalizedString(context, format: 'yyyy-MM-dd');
  }

  /// Format date and time with locale awareness
  ///
  /// Uses 'yyyy-MM-dd HH:mm' format for non-Thai locales
  /// Uses Buddhist Era for Thai locale
  String toLocalizedDateTime(BuildContext context) {
    return toLocalizedString(context, format: 'yyyy-MM-dd HH:mm');
  }

  /// Format date in a shorter format with locale awareness
  ///
  /// Uses 'yyyy/M/d' format for non-Thai locales
  /// Uses Buddhist Era for Thai locale
  String toLocalizedShortDate(BuildContext context) {
    return toLocalizedString(context, format: 'yyyy/M/d');
  }

  /// Internal method to format date in Buddhist Era
  String _formatBuddhistEra(DateTime date, String format) {
    // Buddhist Era = Gregorian year + 543
    final beYear = date.year + 543;

    // Replace year in the formatted string
    String formatted = DateFormat(format).format(date);

    // Replace all occurrences of the Gregorian year with BE year
    // Handle different year formats: yyyy, yy
    if (format.contains('yyyy')) {
      formatted = formatted.replaceAll(date.year.toString(), beYear.toString());
    } else if (format.contains('yy')) {
      // For 2-digit year format, use last 2 digits of BE year
      final beYearShort = (beYear % 100).toString().padLeft(2, '0');
      final gregYearShort = (date.year % 100).toString().padLeft(2, '0');
      formatted = formatted.replaceAll(gregYearShort, beYearShort);
    }

    return formatted;
  }
}

/// Extension for backward compatibility and convenience
///
/// This maintains the existing API while adding locale support
extension DateOnlyLocalized on DateTime? {
  /// Get date-only string with locale awareness
  ///
  /// **IMPORTANT**: This requires BuildContext. For new code, use:
  /// `date.toLocalizedDateOnly(context)` instead.
  ///
  /// For existing code without context, use the old `dateOnly()` method
  /// which will continue to work but won't support Buddhist Era.
  String dateOnlyLocalized(BuildContext context) {
    return toLocalizedDateOnly(context);
  }
}

/// Helper class for working with localized dates
class LocalizedDateHelper {
  /// Check if current locale is Thai
  static bool isThaiLocale(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'th';
  }

  /// Convert Gregorian year to Buddhist Era year
  static int toBuddhistYear(int gregorianYear) {
    return gregorianYear + 543;
  }

  /// Convert Buddhist Era year to Gregorian year
  static int toGregorianYear(int buddhistYear) {
    return buddhistYear - 543;
  }

  /// Format a DateTime with automatic locale detection
  static String formatDate(
    BuildContext context,
    DateTime? date, {
    String format = 'yyyy-MM-dd',
  }) {
    return date.toLocalizedString(context, format: format);
  }

  /// Parse a date string considering the current locale
  ///
  /// For Thai locale, assumes the year is in Buddhist Era and converts to Gregorian
  /// before creating DateTime object.
  static DateTime? parseLocalizedDate(
    BuildContext context,
    String dateString, {
    String format = 'yyyy-MM-dd',
  }) {
    if (dateString.isEmpty) return null;

    try {
      final locale = Localizations.localeOf(context);

      // For Thai locale, convert BE year back to Gregorian before parsing
      if (locale.languageCode == 'th') {
        // Extract year from the date string based on format
        final parsed = DateFormat(format).parse(dateString);
        // The parsed year is BE, convert to Gregorian
        final gregorianYear = parsed.year - 543;
        return DateTime(
          gregorianYear,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
        );
      }

      return DateFormat(format).parse(dateString);
    } catch (e) {
      return null;
    }
  }
}
