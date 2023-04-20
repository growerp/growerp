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

import 'package:growerp_core/growerp_core.dart';

import 'accounting.dart';

class AccountingAPIRepository extends APIRepository {
  AccountingAPIRepository(super.apiKey);

  Future<ApiResult<LedgerReport>> getBalanceSheet(String periodName) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/BalanceSheet', apiKey!,
          queryParameters: <String, dynamic>{
            'periodName': periodName,
          });
      return getResponse<LedgerReport>(
          "ledgerReport", response, (json) => LedgerReport.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<LedgerReport>> getBalanceSummary(
    String periodName,
  ) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/BalanceSummary', apiKey!,
          queryParameters: <String, dynamic>{
            'periodName': periodName,
          });
      return getResponse<LedgerReport>(
          "ledgerReport", response, (json) => LedgerReport.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<LedgerReport>> getLedger() async {
    try {
      final response =
          await dioClient.get('rest/s1/growerp/100/Ledger', apiKey!);
      return getResponse<LedgerReport>(
          "ledgerReport", response, (json) => LedgerReport.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }
}
