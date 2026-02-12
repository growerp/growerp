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

import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Service to handle deep linking in GrowERP applications.
/// Listens for both custom schemes (growerp://) and HTTPS App Links/Universal Links.
class DeepLinkService {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  GoRouter? _router;

  /// Initializes the deep link service with the provided router.
  /// Also handles the initial link if the app was launched via a deep link.
  Future<void> initialize({required GoRouter router}) async {
    _router = router;

    try {
      // Handle initial link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('DeepLinkService: Initial link received: $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('DeepLinkService: Error getting initial link: $e');
    }

    // Handle incoming links when app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('DeepLinkService: Incoming link received: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('DeepLinkService: Error listening for links: $err');
      },
    );
  }

  /// Handles a deep link URI by extracting the path and navigating.
  void _handleDeepLink(Uri uri) {
    if (_router == null) {
      debugPrint('DeepLinkService: Router not initialized, ignoring link');
      return;
    }

    final path = _extractPath(uri);
    debugPrint('DeepLinkService: Extracted path: $path');

    if (path.isNotEmpty) {
      debugPrint('DeepLinkService: Navigating to $path');
      _router!.go(path);
    }
  }

  /// Extracts the navigation path from the URI.
  /// Supports both custom schemes (growerp://admin/user) and HTTPS (https://admin.growerp.com/user)
  String _extractPath(Uri uri) {
    // For custom schemes like growerp://admin/user, the path would be /user
    // For HTTPS links like https://admin.growerp.com/user, the path would also be /user

    // uri.path usually starts with /
    String path = uri.path;

    // Ensure path starts with /
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    // Append query parameters if any
    if (uri.hasQuery) {
      path += '?${uri.query}';
    }

    // If the path is just /, it's the home screen
    return path;
  }

  /// Disposes of the subscription.
  void dispose() {
    _linkSubscription?.cancel();
    _router = null;
    debugPrint('DeepLinkService: Disposed');
  }

  /// Checks if a URI is a valid deep link for the current application.
  /// host should match the app name (e.g., 'admin', 'support', 'hotel')
  bool isValidDeepLink(Uri uri, String expectedHost) {
    final bool isSchemeMatch = uri.scheme == 'growerp' || uri.scheme == 'https';
    final bool isHostMatch =
        uri.host == expectedHost || uri.host == '$expectedHost.growerp.com';
    return isSchemeMatch && isHostMatch;
  }
}
