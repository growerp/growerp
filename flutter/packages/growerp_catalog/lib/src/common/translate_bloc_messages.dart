/*
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
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
