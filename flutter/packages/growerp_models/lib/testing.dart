/// Shared unit-test helpers, import from a package's test/shared/ only:
/// `import 'package:growerp_models/testing.dart';`
library;

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

import 'growerp_models.dart';

class MockRestClient extends Mock implements RestClient {}

/// A DioException as the Moqui backend returns it: `{"errors": message}`.
/// getDioError turns it into [message].
DioException dioError(String message, {int statusCode = 400}) {
  final requestOptions = RequestOptions(path: 'rest/s1/growerp/100');
  return DioException(
    requestOptions: requestOptions,
    response: Response(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: {'errors': message},
    ),
  );
}
