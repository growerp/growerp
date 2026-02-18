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

import 'package:web/web.dart' as web;

/// Web implementation: forces a hard reload bypassing cache
void reloadPage() {
  // Add cache-busting query param to bypass browser cache
  final location = web.window.location;
  final currentUrl = location.href;
  final separator = currentUrl.contains('?') ? '&' : '?';
  final cacheBuster = 'v=${DateTime.now().millisecondsSinceEpoch}';
  location.replace('$currentUrl$separator$cacheBuster');
}
