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

  Future<ApiResult<List<TimePeriod>>> getTimePeriods() async {
    try {
      final response =
          await dioClient.get('rest/s1/growerp/100/Timeperiod', apiKey!);
      return getResponseList<TimePeriod>(
          "timePeriods", response, (json) => TimePeriod.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<LedgerJournal>>> getLedgerJournal({
    int? start,
    int? limit,
    String? ledgerJournalId,
    bool? my,
    String? searchString,
  }) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/LedgerJournal', apiKey!,
          queryParameters: <String, dynamic>{
            'ledgerJournalId': ledgerJournalId,
            'start': start,
            'limit': limit,
            'search': searchString
          });
      return getResponseList<LedgerJournal>("ledgerJournalList", response,
          (json) => LedgerJournal.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<LedgerJournal>> createLedgerJournal(
      LedgerJournal ledgerJournal) async {
    try {
      final response = await dioClient.post(
          'rest/s1/growerp/100/LedgerJournal', apiKey!,
          data: <String, dynamic>{
            'ledgerJournal': jsonEncode(ledgerJournal.toJson()),
            'moquiSessionToken': sessionToken
          });
      return getResponse<LedgerJournal>(
          "ledgerJournal", response, (json) => LedgerJournal.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<LedgerJournal>> updateLedgerJournal(
      LedgerJournal ledgerJournal) async {
    try {
      final response = await dioClient.patch(
          'rest/s1/growerp/100/LedgerJournal', apiKey!,
          data: <String, dynamic>{
            'ledgerJournal': jsonEncode(ledgerJournal.toJson()),
            'moquiSessionToken': sessionToken
          });
      return getResponse<LedgerJournal>(
          "ledgerJournal", response, (json) => LedgerJournal.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }
}
