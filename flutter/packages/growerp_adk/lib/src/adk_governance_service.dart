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
