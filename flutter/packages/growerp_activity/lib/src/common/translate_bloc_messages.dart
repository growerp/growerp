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

import 'package:growerp_activity/growerp_activity.dart';

/// Translate Activity BLoC message keys to localized strings
String translateActivityBlocMessage(
  String? messageKey,
  ActivityLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Fallback: return the key itself
  return messageKey;
}
