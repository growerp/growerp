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

import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;

/// Holds information about a required force update
class ForceUpdateInfo {
  final bool forceUpdate;
  final String? minVersion;
  final String? updateUrl;
  final String? currentVersion;

  const ForceUpdateInfo({
    required this.forceUpdate,
    this.minVersion,
    this.updateUrl,
    this.currentVersion,
  });

  /// No force update required
  static const ForceUpdateInfo none = ForceUpdateInfo(forceUpdate: false);
}

/// Returns the current platform as a string for the backend service
/// Returns: 'android', 'ios', 'macos', 'linux', 'windows', or 'web'
String _getCurrentPlatform() {
  if (kIsWeb) {
    return 'web';
  }
  try {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    if (Platform.isWindows) return 'windows';
  } catch (e) {
    // Platform not available, assume web
  }
  return 'web';
}

/// Checks if there is an override for the production/test backend URL
/// Updates the GlobalConfiguration with the new backend URL if available
/// Returns ForceUpdateInfo if a force update is required
///
/// [classificationId] - The application classification ID
/// [version] - The application version
Future<ForceUpdateInfo> getBackendUrlOverride(
  String classificationId,
  String version,
) async {
  late http.Response response;
  late String backendBaseUrl, backendUrl, databaseUrl, chatUrl, secure;
  final String platform = _getCurrentPlatform();
  try {
    if (kDebugMode) {
      bool android = false;
      try {
        if (Platform.isAndroid) {
          android = true;
        }
        // ignore: empty_catches
      } catch (e) {}

      backendBaseUrl = android == true
          ? 'http://10.0.2.2:8080'
          : 'http://localhost:8080';
      databaseUrl = 'databaseUrlDebug';
      chatUrl = 'chatUrlDebug';
      secure = '';
    } else {
      backendBaseUrl = 'https://backend.growerp.com';
      databaseUrl = 'databaseUrl';
      chatUrl = 'chatUrl';
      secure = 's';
    }
    backendUrl =
        '$backendBaseUrl/rest/s1/growerp/100/BackendUrl?version='
        '$version&applicationId=$classificationId&platform=$platform';
    response = await http.get(Uri.parse(backendUrl));

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);

      // Check for force update requirement
      final bool requiresForceUpdate = responseBody['forceUpdate'] == true;
      if (requiresForceUpdate) {
        return ForceUpdateInfo(
          forceUpdate: true,
          minVersion: responseBody['minVersion'] as String?,
          updateUrl: responseBody['updateUrl'] as String?,
          currentVersion: version,
        );
      }

      // Process backend URL override
      String? appBackendUrl = responseBody['backendUrl'];
      if (appBackendUrl != null) {
        if (appBackendUrl.contains('localhost')) secure = '';
        if (appBackendUrl.endsWith('/')) {
          appBackendUrl = appBackendUrl.substring(0, appBackendUrl.length - 1);
        }
        GlobalConfiguration().updateValue(
          databaseUrl,
          "http$secure://$appBackendUrl",
        );
        GlobalConfiguration().updateValue(
          chatUrl,
          "ws$secure://$appBackendUrl",
        );
        GlobalConfiguration().updateValue("test", true);
      } else {
        // always show in debug mode when backend url not provided
        if (kDebugMode) {
          GlobalConfiguration().updateValue("test", true);
        }
      }
    }
  } catch (error) {
    debugPrint('===get backend url: $backendUrl error: $error');
  }

  return ForceUpdateInfo.none;
}
