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

import 'package:url_launcher/url_launcher.dart';
import 'open_external_url_stub.dart'
    if (dart.library.io) 'open_external_url_io.dart';

/// Open [uri] in the external browser/application, returning false when it
/// could not be opened so the caller can tell the user.
///
/// Deliberately does not call `canLaunchUrl`: on Linux that maps to
/// `g_app_info_get_default_for_uri_scheme`, which returns null in sandboxed
/// environments even when launching would work, silently skipping the launch.
Future<bool> openExternalUrl(Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
  } catch (_) {
    // fall through to the shell fallback
  }
  return openUrlWithShell(uri.toString());
}
