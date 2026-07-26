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

import 'package:growerp_website/growerp_website.dart';

/// Translate Website BLoC message keys to localized strings
///
/// Supports direct l10n keys
/// Example: 'websiteUpdateSuccess' -> "Website updated successfully"
String translateWebsiteBlocMessage(
  String? messageKey,
  WebsiteLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Handle direct l10n keys (new pattern)
  switch (messageKey) {
    case 'websiteUpdateSuccess':
      return localizations.websiteUpdateSuccess;
    default:
      return messageKey;
  }
}

/// Translate Content BLoC message keys to localized strings
///
/// Supports parameterized messages using format: 'key:param'
/// Example: 'contentUpdateSuccess:Home Page' -> "Content Home Page updated successfully"
String translateContentBlocMessage(
  String? messageKey,
  WebsiteLocalizations localizations,
) {
  if (messageKey == null || messageKey.isEmpty) return '';

  // Check if message has parameters (format: key:param)
  if (messageKey.contains(':')) {
    final parts = messageKey.split(':');
    final key = parts[0];
    final param = parts.length > 1 ? parts.sublist(1).join(':') : '';

    switch (key) {
      case 'contentUpdateSuccess':
        return localizations.contentUpdateSuccess(param);
      default:
        break;
    }
  }

  // Fallback: return the key itself
  return messageKey;
}
