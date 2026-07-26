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

import 'package:growerp_models/growerp_models.dart';
import 'package:growerp_core/growerp_core.dart';

/// Thin REST wrapper for the tenant-scoped agent governance endpoints.
/// All calls are owner-scoped server-side — a company only ever sees and
/// decides its own agents' actions and approvals.
class AdkGovernanceService {
  final RestClient _client;

  AdkGovernanceService._(this._client);

  static Future<AdkGovernanceService> create() async {
    final client = RestClient(await buildDioClient());
    return AdkGovernanceService._(client);
  }

  Future<List<AdkActionLog>> actions(
      {String? configId, String? search, int limit = 100}) async {
    final result = await _client.getAdkActions(
        configId: configId, search: search, limit: limit);
    return result.adkActions;
  }

  Future<List<AdkActionLog>> systemUsage(
      {String? search, int limit = 100}) async {
    final result = await _client.getAdkSystemUsage(
        search: search, limit: limit);
    return result.adkActions;
  }

  Future<List<AdkApproval>> approvals(
      {String status = 'pending', String? search}) async {
    final result = await _client.getAdkApprovals(status: status, search: search);
    return result.adkApprovals;
  }

  Future<void> approve(String adkApprovalId) async {
    await _client.updateAdkApproval(
        adkApprovalId: adkApprovalId, decision: 'approved');
  }

  Future<void> reject(String adkApprovalId) async {
    await _client.updateAdkApproval(
        adkApprovalId: adkApprovalId, decision: 'rejected');
  }
}
