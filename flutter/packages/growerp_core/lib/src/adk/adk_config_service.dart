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
import 'package:dio/dio.dart';
import '../services/build_dio_client.dart';
import 'adk_agent_config_model.dart';

/// Thin Dio wrapper for the /adk/configs REST endpoints added to AdkDevServlet.
class AdkConfigService {
  final Dio _dio;

  AdkConfigService._(this._dio);

  static Future<AdkConfigService> create() async {
    final dio = await buildDioClient();
    return AdkConfigService._(dio);
  }

  Future<List<AdkAgentConfig>> list() async {
    final resp = await _dio.get<String>(
      '/adk/configs',
      options: Options(responseType: ResponseType.plain),
    );
    final data = jsonDecode(resp.data!) as List;
    return data
        .map((e) => AdkAgentConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> save(AdkAgentConfig cfg, {String? apiKey}) async {
    final body = cfg.toJson();
    if (apiKey != null && apiKey.isNotEmpty) body['apiKey'] = apiKey;
    final resp = await _dio.post<String>(
      '/adk/configs',
      data: jsonEncode(body),
      options: Options(
        contentType: 'application/json',
        responseType: ResponseType.plain,
      ),
    );
    final result = jsonDecode(resp.data!) as Map<String, dynamic>;
    return result['adkAgentConfigId'] as String;
  }

  Future<void> delete(String configId) async {
    await _dio.delete<void>('/adk/configs/$configId');
  }
}
