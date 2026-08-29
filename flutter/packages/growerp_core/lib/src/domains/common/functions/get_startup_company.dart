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

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// build time default: --dart-define=COMPANY_PARTY_ID=...
const String _companyPartyIdDefine = String.fromEnvironment('COMPANY_PARTY_ID');

const String _prefKey = 'companyPartyId';
const String _paramName = 'companyPartyId';

/// Optional company the app is started for, on any platform:
/// - desktop: --companyPartyId=100000 on the command line
///   (under flutter run: --dart-entrypoint-args=--companyPartyId=100000)
/// - web: ?companyPartyId=100000 in the url
/// - mobile: a deeplink like growerp://admin?companyPartyId=100000
/// - any platform: --dart-define=COMPANY_PARTY_ID=100000 at build time
///   or the 'singleCompany' key in assets/cfg/app_settings.json
///
/// A value provided at launch is remembered, so the next start without any
/// parameter uses the same company. An explicit empty value(--companyPartyId=)
/// forgets a remembered value again.
///
/// When no company id is available the web hostname is used, as before.
/// Returns null when nothing was found: the app then shows all companies.
Future<Company?> getStartupCompany(
  RestClient restClient, {
  List<String> args = const [],
}) async {
  final String? provided =
      _fromArgs(args) ?? _fromUri(Uri.base) ?? await _fromDeepLink();

  final prefs = await SharedPreferences.getInstance();
  if (provided != null) {
    // remember the company provided at launch, or forget it when empty
    if (provided.isEmpty) {
      await prefs.remove(_prefKey);
    } else {
      await prefs.setString(_prefKey, provided);
    }
  }
  String companyPartyId = provided ?? '';
  if (companyPartyId.isEmpty) companyPartyId = prefs.getString(_prefKey) ?? '';
  if (companyPartyId.isEmpty) companyPartyId = _companyPartyIdDefine;
  if (companyPartyId.isEmpty) {
    companyPartyId = GlobalConfiguration().get('singleCompany') ?? '';
  }

  if (companyPartyId.isEmpty) {
    // no company id: on the web the hostname decides which company
    if (!kIsWeb || Uri.base.host.isEmpty) return null;
    try {
      final company = await restClient.getCompanyFromHost(Uri.base.host);
      return company.partyId == null ? null : company;
    } catch (e) {
      debugPrint('=== company for host: ${Uri.base.host} not found: $e');
      return null;
    }
  }

  GlobalConfiguration().updateValue('singleCompany', companyPartyId);
  try {
    final company = await restClient.getPublicCompany(
      companyPartyId: companyPartyId,
    );
    if (company.partyId == null) {
      debugPrint('=== company: $companyPartyId not found');
      return null;
    }
    debugPrint('=== startup company: ${company.name}[${company.partyId}]');
    return company;
  } catch (e) {
    debugPrint('=== getting company: $companyPartyId error: $e');
    return null;
  }
}

/// --companyPartyId=100000 or --companyPartyId 100000
String? _fromArgs(List<String> args) {
  for (int i = 0; i < args.length; i++) {
    if (args[i].startsWith('--$_paramName=')) {
      return args[i].substring('--$_paramName='.length);
    }
    if (args[i] == '--$_paramName') {
      return i + 1 < args.length ? args[i + 1] : '';
    }
  }
  return null;
}

String? _fromUri(Uri uri) => uri.queryParameters[_paramName];

Future<String?> _fromDeepLink() async {
  try {
    final uri = await AppLinks().getInitialLink();
    return uri == null ? null : _fromUri(uri);
  } catch (e) {
    debugPrint('=== getting deeplink error: $e');
    return null;
  }
}
