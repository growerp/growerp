import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<String> getDioError(e) async {
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
    var box = await Hive.openBox('growerp');
    box.delete('apiKey');
  }
  return returnMessage;
}
