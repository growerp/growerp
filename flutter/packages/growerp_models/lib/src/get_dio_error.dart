import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getDioError(e) async {
  String returnMessage = '';
  if (e is DioException) {
    if (e.response != null) {
      try {
        // Try to decode as JSON, but handle if not a JSON string
        final dynamic responseData = e.response!.data;
        final dynamic decoded = responseData is String
            ? json.decode(responseData)
            : responseData;
        if (decoded is Map<String, dynamic>) {
          // Extract and format error messages properly - only show the clean error text
          String errorMessage = '';
          if (decoded['errors'] != null &&
              decoded['errors'].toString().isNotEmpty) {
            errorMessage = decoded['errors'].toString();
            // Clean up the message by removing extra whitespace and formatting
            errorMessage = errorMessage.replaceAll('\\n', '\n').trim();

            // Return only the clean error message without technical prefixes
            returnMessage = errorMessage;
          } else if (decoded['errorCode'] != null) {
            returnMessage = 'Error code: ${decoded['errorCode']}';
          }
        } else {
          // Fallback to technical error for non-JSON responses
          returnMessage = 'Server error occurred';
        }
      } catch (_) {
        returnMessage = 'Server error occurred';
      }
    } else {
      // Handle cases where there's no response (connection issues, etc.)
      late String expression;
      switch (e.type) {
        case DioExceptionType.connectionError:
          expression = "Connection error";
        case DioExceptionType.receiveTimeout:
          expression = "Request timeout";
        case DioExceptionType.connectionTimeout:
          expression = "Connection timeout";
        case DioExceptionType.sendTimeout:
          expression = "Send timeout";
        case DioExceptionType.cancel:
          expression = "Request cancelled";
        default:
          expression = "Network error";
      }
      returnMessage = expression;
    }
  } else if (e is FormatException) {
    returnMessage = 'Invalid data format';
  } else {
    returnMessage = 'An error occurred';
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
