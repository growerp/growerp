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

import 'package:growerp_models/growerp_models.dart';
import '../services/build_dio_client.dart';

class AdkConfigService {
  final RestClient _client;

  AdkConfigService._(this._client);

  static Future<AdkConfigService> create() async {
    final client = RestClient(await buildDioClient());
    return AdkConfigService._(client);
  }

  Future<List<AdkAgentConfig>> list() async {
    final result = await _client.getAdkAgentConfigs();
    return result.adkAgentConfigs;
  }

  Future<AdkAgentConfig> save(AdkAgentConfig cfg, {String? apiKey}) async {
    if (cfg.adkAgentConfigId == null || cfg.adkAgentConfigId!.isEmpty) {
      return _client.createAdkAgentConfig(
        agentName: cfg.agentName,
        modelName: cfg.modelName,
        llmProvider: cfg.llmProvider,
        apiKey: apiKey,
        instruction: cfg.instruction,
        description: cfg.description,
        scheduleExpression: cfg.scheduleExpression,
        scheduleEnabled: cfg.scheduleEnabled,
        schedulePrompt: cfg.schedulePrompt,
        scheduleChatRoomId: cfg.scheduleChatRoomId,
      );
    }
    return _client.updateAdkAgentConfig(
      adkAgentConfigId: cfg.adkAgentConfigId!,
      agentName: cfg.agentName,
      modelName: cfg.modelName,
      llmProvider: cfg.llmProvider,
      apiKey: apiKey,
      instruction: cfg.instruction,
      description: cfg.description,
      scheduleExpression: cfg.scheduleExpression,
      scheduleEnabled: cfg.scheduleEnabled,
      schedulePrompt: cfg.schedulePrompt,
      scheduleChatRoomId: cfg.scheduleChatRoomId,
    );
  }

  Future<void> delete(String configId) async {
    await _client.deleteAdkAgentConfig(adkAgentConfigId: configId);
  }
}
