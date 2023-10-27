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
  return "exception: $expression ${exception.message} error: ${e.response}";
}
