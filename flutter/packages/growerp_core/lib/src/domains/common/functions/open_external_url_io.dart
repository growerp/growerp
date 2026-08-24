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

import 'dart:io';

/// Linux fallback when url_launcher cannot open a URL.
///
/// url_launcher_linux uses `gtk_show_uri_on_window`, which fails inside a
/// strictly confined snap (the portal call errors and the snap only sees its
/// own `xdg-open.desktop`). `/usr/bin/xdg-open` is snapd's shim and does reach
/// the host browser, so run it directly.
Future<bool> openUrlWithShell(String url) async {
  if (!Platform.isLinux) return false;
  try {
    final result = await Process.run('xdg-open', [url]);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}
