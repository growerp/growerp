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

import 'package:growerp_inventory/growerp_inventory.dart';

/// Translate Asset BLoC message keys to localized strings
///
/// Supports parameterized messages using format: 'key:param'
/// Example: 'assetUpdateSuccess:Laptop-001' -> "Asset Laptop-001 updated successfully"
String translateAssetBlocMessage(
  String? messageKey,
  InventoryLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Check if message has parameters (format: key:param)
  if (messageKey.contains(':')) {
    final parts = messageKey.split(':');
    final key = parts[0];
    final param = parts.length > 1 ? parts.sublist(1).join(':') : '';

    switch (key) {
      case 'assetUpdateSuccess':
        return localizations.assetUpdateSuccess(param);
      case 'assetAddSuccess':
        return localizations.assetAddSuccess(param);
      default:
        break;
    }
  }

  // Fallback: return the key itself
  return messageKey;
}

/// Translate Location BLoC message keys to localized strings
String translateLocationBlocMessage(
  String? messageKey,
  InventoryLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Fallback: return the key itself
  return messageKey;
}
