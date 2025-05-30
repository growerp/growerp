import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<String> getDioError(e) async {
  DioException exception =
      DioException(response: e.response, requestOptions: e.requestOptions);
  late String expression;
  switch (exception.type) {
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
      expression = "Exception unknown:  ${exception.error}";
  }
  String returnMessage = '';
  if (exception.type != DioExceptionType.unknown) {
    returnMessage += "$expression: ${exception.message}";
  }
  if (e.response != null) {
    Map<String, dynamic> response = json.decode(e.response.toString());
    returnMessage += "${response['errors']}[${response['errorCode']}]";
  }
  if (returnMessage.isEmpty) returnMessage = "Server Connection error";

  // remove key from db when not valid
  if (returnMessage == 'Login key not valid ') {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('apiKey');
    returnMessage = 'Login key expired, please login again';
  }
  return returnMessage;
}
