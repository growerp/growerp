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

/// Checks if there is an override for the production/test backend URL
/// Updates the GlobalConfiguration with the new backend URL if available
///
/// [classificationId] - The application classification ID
/// [version] - The application version
Future<void> getBackendUrlOverride(
  String classificationId,
  String version,
) async {
  late http.Response response;
  late String backendBaseUrl, backendUrl, databaseUrl, chatUrl, secure;
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
        '$version&applicationId=$classificationId';
    response = await http.get(Uri.parse(backendUrl));
    String? appBackendUrl = jsonDecode(response.body)['backendUrl'];
    if (response.statusCode == 200 && appBackendUrl != null) {
      if (appBackendUrl.contains('localhost')) secure = '';
      GlobalConfiguration().updateValue(
        databaseUrl,
        "http$secure://${jsonDecode(response.body)['backendUrl']}",
      );
      GlobalConfiguration().updateValue(
        chatUrl,
        "ws$secure://${jsonDecode(response.body)['backendUrl']}",
      );
      GlobalConfiguration().updateValue("test", true);
    } else {
      // always show in debug mode when backend url not provided
      if (kDebugMode) {
        GlobalConfiguration().updateValue("test", true);
      }
    }
  } catch (error) {
    debugPrint('===get backend url: $backendUrl error: $error');
  }
}
