import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getDioError(e) async {
  String returnMessage = '';
  if (e is DioException) {
    late String expression;
    switch (e.type) {
      case DioExceptionType.connectionError:
        expression = "Connection error:";
      case DioExceptionType.badResponse:
        expression = "Bad response:";
      case DioExceptionType.badCertificate:
        expression = "Bad certificate:";
      case DioExceptionType.receiveTimeout:
        expression = "Receive timeout:";
      case DioExceptionType.connectionTimeout:
        expression = "Connection timeout:";
      case DioExceptionType.sendTimeout:
        expression = "Send timeout:";
      case DioExceptionType.cancel:
        expression = "Request cancelled:";
      case DioExceptionType.unknown:
        expression = "Exception unknown:  ${e.error}";
    }
    if (e.type != DioExceptionType.unknown) {
      returnMessage += "$expression ${e.message}";
    } else {
      returnMessage += expression;
    }
    if (e.response != null) {
      try {
        // Try to decode as JSON, but handle if not a JSON string
        final dynamic decoded = e.response is String
            ? json.decode(e.response as String)
            : e.response;
        if (decoded is Map<String, dynamic>) {
          returnMessage +=
              " ${decoded['errors'] ?? ''}[${decoded['errorCode'] ?? ''}]";
        } else {
          returnMessage = ' ${e.response.toString()}';
        }
      } catch (_) {
        returnMessage += ' ${e.response.toString()}';
      }
    }
  } else if (e is FormatException) {
    returnMessage = 'FormatException: ${e.message}';
  } else {
    returnMessage = e.toString();
  }

  if (returnMessage.trim().isEmpty) returnMessage = "Server Connection error";

  // remove key from db when not valid
  if (returnMessage.trim() == 'Login key not valid') {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('apiKey');
    returnMessage = 'Login key expired, please login again';
  }
  return returnMessage.trim();
}
