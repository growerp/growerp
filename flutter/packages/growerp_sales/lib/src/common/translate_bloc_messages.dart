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

import 'package:growerp_sales/growerp_sales.dart';

/// Translate Opportunity BLoC message keys to localized strings
///
/// Supports parameterized messages using format: 'key:param'
/// Example: 'opportunityAddSuccess:Big Deal' -> "Opportunity Big Deal added successfully"
String translateOpportunityBlocMessage(
  String? messageKey,
  SalesLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Check if message has parameters (format: key:param)
  if (messageKey.contains(':')) {
    final parts = messageKey.split(':');
    final key = parts[0];
    final param = parts.length > 1 ? parts.sublist(1).join(':') : '';

    switch (key) {
      case 'opportunityAddSuccess':
        return localizations.opportunityAddSuccess(param);
      case 'opportunityDeleteSuccess':
        return localizations.opportunityDeleteSuccess(param);
      default:
        break;
    }
  }

  // Fallback: return the key itself
  return messageKey;
}
