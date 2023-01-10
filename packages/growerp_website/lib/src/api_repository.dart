import 'dart:convert';
import 'package:growerp_core/services/api_result.dart';
import 'package:growerp_core/services/network_exceptions.dart';
import 'package:growerp_core/api_repository.dart';
import 'website/website.dart';

class WebsiteAPIRepository extends APIRepository {
  String? apiKey;

  WebsiteAPIRepository(this.apiKey) : super();

  Future<ApiResult<Website>> getWebsite() async {
    try {
      final response = await dioClient.get(
          'rest/s1/growerp/100/Website', apiKey!,
          queryParameters: <String, dynamic>{
            'classificationId': classificationId
          });
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
            'content': jsonEncode(content.toJson()),
            'classificationId': classificationId
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
            'classificationId': classificationId,
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
          'rest/s1/growerp/100/Obsidian', apiKey!,
          data: <String, dynamic>{
            'obsidian': jsonEncode(obsidian.toJson()),
            'classificationId': classificationId,
            'moquiSessionToken': sessionToken
          });
      return getResponse<Website>(
          "website", response, (json) => Website.fromJson(json));
    } on Exception catch (e) {
      return ApiResult.failure(error: NetworkExceptions.getDioException(e));
    }
  }
}
