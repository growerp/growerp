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

import 'package:growerp_catalog/growerp_catalog.dart';

/// Translate Product BLoC message keys to localized strings
///
/// Supports parameterized messages using format: 'key:param'
/// Example: 'productUpdateSuccess:Widget Pro' -> "Product Widget Pro updated successfully"
String translateProductBlocMessage(
  String? messageKey,
  CatalogLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Check if message has parameters (format: key:param)
  if (messageKey.contains(':')) {
    final parts = messageKey.split(':');
    final key = parts[0];
    final param = parts.length > 1 ? parts.sublist(1).join(':') : '';

    switch (key) {
      case 'productUpdateSuccess':
        return localizations.productUpdateSuccess(param);
      case 'productAddSuccess':
        return localizations.productAddSuccess(param);
      case 'productDeleteSuccess':
        return localizations.productDeleteSuccess(param);
      default:
        break;
    }
  }

  // Fallback: return the key itself
  return messageKey;
}

/// Translate Category BLoC message keys to localized strings
///
/// Supports parameterized messages using format: 'key:param'
String translateCategoryBlocMessage(
  String? messageKey,
  CatalogLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Check if message has parameters (format: key:param)
  if (messageKey.contains(':')) {
    final parts = messageKey.split(':');
    final key = parts[0];
    final param = parts.length > 1 ? parts.sublist(1).join(':') : '';

    switch (key) {
      case 'categoryUpdateSuccess':
        return localizations.categoryUpdateSuccess(param);
      case 'categoryAddSuccess':
        return localizations.categoryAddSuccess(param);
      case 'categoryDeleteSuccess':
        return localizations.categoryDeleteSuccess(param);
      default:
        break;
    }
  }

  // Fallback: return the key itself
  return messageKey;
}

/// Translate Subscription BLoC message keys to localized strings
///
/// Subscriptions use simple (non-parameterized) messages
String translateSubscriptionBlocMessage(
  String? messageKey,
  CatalogLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Handle direct l10n keys (new pattern)
  switch (messageKey) {
    case 'subscriptionUpdateSuccess':
      return localizations.subscriptionUpdateSuccess;
    case 'subscriptionAddSuccess':
      return localizations.subscriptionAddSuccess;
    case 'subscriptionDeleteSuccess':
      return localizations.subscriptionDeleteSuccess;
    default:
      return messageKey;
  }
}
