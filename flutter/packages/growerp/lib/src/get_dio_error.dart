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
 * 
 * CLI-specific error handling that doesn't depend on Flutter.
 * Uses Hive for storage instead of SharedPreferences.
 */

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

/// Get a user-friendly error message from a Dio exception.
/// This is a pure Dart implementation that uses Hive instead of SharedPreferences.
Future<String> getDioError(dynamic e) async {
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

            // A request that left the client after logout arrives keyless and
            // the backend answers with its internal authz text; the user just
            // signed out, say so instead of leaking that text verbatim.
            if (errorMessage.contains('[No User]') &&
                errorMessage.contains('is not authorized for')) {
              return 'You have been signed out, please log in again.';
            }

            // Try to extract the inner error message from nested JSON errors
            try {
              final RegExp jsonPattern = RegExp(
                r'\{[^}]*"message"\s*:\s*"([^"]+)"',
              );
              final match = jsonPattern.firstMatch(errorMessage);
              if (match != null && match.group(1) != null) {
                errorMessage = match.group(1)!;
              } else {
                errorMessage = errorMessage.replaceAll('\\n', '\n').trim();
              }
            } catch (_) {
              errorMessage = errorMessage.replaceAll('\\n', '\n').trim();
            }

            returnMessage = errorMessage;
          } else if (decoded['errorCode'] != null) {
            returnMessage = 'Error code: ${decoded['errorCode']}';
          }
        } else {
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
    try {
      var box = await Hive.openBox('growerp');
      await box.delete('apiKey');
    } catch (_) {
      // Ignore Hive errors
    }
    returnMessage = 'Login key expired, please login again';
  }
  return returnMessage.trim();
}
