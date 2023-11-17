import 'dart:convert';

import 'package:dio/dio.dart';

String getDioError(e) {
  DioException exception =
      DioException(response: e.response, requestOptions: e.requestOptions);
  late String expression;
  switch (exception.type) {
    case DioExceptionType.connectionError:
      expression = "Connection error:";
      break;
    case DioExceptionType.badResponse:
      expression = "Bad response:";
      break;
    case DioExceptionType.badCertificate:
      expression = "Bad certificate:";
      break;
    case DioExceptionType.receiveTimeout:
      expression = "Receive timeout:";
      break;
    case DioExceptionType.connectionTimeout:
      expression = "Connection timeout:";
      break;
    case DioExceptionType.sendTimeout:
      expression = "Send timeout:";
      break;
    case DioExceptionType.cancel:
      expression = "Request cancelled:";
      break;
    case DioExceptionType.unknown:
      expression = "Exception unknown:  ${exception.error}";
      break;
    default:
      expression = "Connection error";
      break;
  }
  String returnMessage = '';
  Map<String, dynamic> response = json.decode(e.response.toString());

  if (exception.type != DioExceptionType.unknown)
    returnMessage += "$expression: ${exception.message}";
  if (e.response != null)
    returnMessage += "${response['errors']}[${response['errorCode']}]";
  return returnMessage;
}
