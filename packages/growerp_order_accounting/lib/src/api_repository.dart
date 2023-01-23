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

class FinDocAPIRepository extends APIRepository {
  String? apiKey;

  FinDocAPIRepository(this.apiKey) : super();

  Future<ApiResult<FinDoc>> updateFinDoc(FinDoc finDoc) async {
    try {
      final response = await dioClient.patch(
          'rest/s1/growerp/100/FinDoc', apiKey!, data: <String, dynamic>{
        'finDoc': jsonEncode(finDoc.toJson()),
        'moquiSessionToken': sessionToken
      });
      return getResponse<FinDoc>(
          "finDoc", response, (json) => FinDoc.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<FinDoc>> createFinDoc(FinDoc finDoc) async {
    try {
      final response = await dioClient.post(
          'rest/s1/growerp/100/FinDoc', apiKey!, data: <String, dynamic>{
        'finDoc': jsonEncode(finDoc.toJson()),
        'moquiSessionToken': sessionToken
      });
      return getResponse<FinDoc>(
          "finDoc", response, (json) => FinDoc.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<FinDoc>> receiveShipment(FinDoc finDoc) async {
    try {
      final response = await dioClient.patch(
          'rest/s1/growerp/100/FinDocShipment', apiKey!,
          data: <String, dynamic>{
            'finDoc': jsonEncode(finDoc.toJson()),
            'moquiSessionToken': sessionToken
          });
      return getResponse<FinDoc>(
          "finDoc", response, (json) => FinDoc.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  /*Future<ApiResult<FinDoc>> confirmPurchasePayment(String paymentId) async {
    try {
      final response = await dioClient.patch(
          'rest/s1/growerp/100/Payment', apiKey!, data: <String, dynamic>{
        'paymentId': paymentId,
        'moquiSessionToken': sessionToken
      });
      return getResponse<FinDoc>(
          "finDoc", response, (json) => FinDoc.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }
*/
  Future<ApiResult<List<FinDoc>>> getFinDoc(
      {int? start,
      int? limit,
      bool? open,
      bool? sales,
      FinDocType? docType,
      DateTime? startDate,
      String? finDocId,
      String? searchString,
      String? customerCompanyPartyId}) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/FinDoc', apiKey!,
          queryParameters: <String, dynamic>{
            'sales': sales,
            'docType': docType,
            'open': open,
            'finDocId': finDocId,
            'startDate': '${startDate?.year.toString()}-'
                '${startDate?.month.toString().padLeft(2, '0')}-'
                '${startDate?.day.toString().padLeft(2, '0')}',
            'start': start,
            'limit': limit,
            'search': searchString,
            'classificationId': classificationId,
            'customerCompanyPartyId': customerCompanyPartyId,
          });
      return getResponseList<FinDoc>(
          "finDocs", response, (json) => FinDoc.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<String>>> getRentalOccupancy(
      {required String productId}) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/RentalOccupancy', apiKey!,
          queryParameters: <String, dynamic>{
            'productId': productId,
          });
      var json = jsonDecode(response.toString())['rentalFullDates'];
      List<dynamic> list = List.from(json);
      List<String> stringList = [];
      // change members from dynamic to string
      for (String string in list) {
        stringList.add(string);
      }
      return ApiResult.success(data: stringList);
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }
}
