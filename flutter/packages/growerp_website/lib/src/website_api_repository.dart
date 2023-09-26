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
import 'package:growerp_rest/growerp_rest.dart';
import 'package:growerp_models/growerp_models.dart';
import '../growerp_website.dart';

class WebsiteAPIRepository extends APIRepository {
  WebsiteAPIRepository(super.apiKey);

  Future<ApiResult<Website>> getWebsite() async {
    try {
      final response = await dioClient.get(
        'rest/s1/growerp/100/Website',
        apiKey!,
      );
      return getResponse<Website>(
          "website", response, (json) => Website.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Content>> getWebsiteContent(Content content) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/WebsiteContent', apiKey!,
          queryParameters: <String, dynamic>{
            'content': jsonEncode(content.toJson())
          });
      return getResponse<Content>(
          "content", response, (json) => Content.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Content>> uploadWebsiteContent(
      String websiteId, Content content) async {
    try {
      final response = await dioClient.post(
          'rest/s1/growerp/100/WebsiteContent', apiKey!,
          data: <String, dynamic>{
            'content': jsonEncode(content.toJson()),
            'moquiSessionToken': sessionToken
          });
      return getResponse<Content>(
          "content", response, (json) => Content.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Website>> updateWebsite(Website website) async {
    try {
      final response = await dioClient.patch(
          'rest/s1/growerp/100/Website', apiKey!, data: <String, dynamic>{
        'website': jsonEncode(website.toJson()),
        'moquiSessionToken': sessionToken
      });
      return getResponse<Website>(
          "website", response, (json) => Website.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<Website>> obsUpload(Obsidian obsidian) async {
    try {
      final response = await dioClient.post(
          'rest/s1/growerp/100/Obsidian', apiKey!, data: <String, dynamic>{
        'obsidian': jsonEncode(obsidian.toJson()),
        'moquiSessionToken': sessionToken
      });
      return getResponse<Website>(
          "website", response, (json) => Website.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }

  Future<ApiResult<List<Category>>> getCategory(
      {int? start,
      int? limit,
      String? companyPartyId,
      String? filter,
      String? searchString}) async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/Categories', apiKey,
          queryParameters: <String, dynamic>{
            'start': start,
            'limit': limit,
            'companyPartyId': companyPartyId,
            'filter': filter,
            'search': searchString,
          });
      return getResponseList<Category>(
          "categories", response, (json) => Category.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }
}
