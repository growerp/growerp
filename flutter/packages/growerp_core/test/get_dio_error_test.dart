import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:growerp_core/growerp_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

DioException response(Object? data, {int status = 400}) {
  final options = RequestOptions(path: 'rest/s1/growerp/100/X');
  return DioException(
    requestOptions: options,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

DioException noResponse(DioExceptionType type) =>
    DioException(requestOptions: RequestOptions(), type: type);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('getDioError backend errors', () {
    test('getDioError_errorsMap_returnsTrimmedErrorText', () async {
      expect(
        await getDioError(response({'errors': '  Product name required \n'})),
        'Product name required',
      );
    });

    test('getDioError_errorsAsJsonString_isDecodedFirst', () async {
      expect(
        await getDioError(response('{"errors": "Not allowed"}')),
        'Not allowed',
      );
    });

    test('getDioError_nestedAiError_returnsInnerMessage', () async {
      // Arrange: an LLM provider error relayed by the backend
      final error = response({
        'errors':
            'Failed to generate: { "error": { "message": "Model overloaded" } }',
      });
      // Act + Assert
      expect(await getDioError(error), 'Model overloaded');
    });

    test('getDioError_escapedNewlines_becomeRealNewlines', () async {
      expect(
        await getDioError(response({'errors': r'line one\nline two'})),
        'line one\nline two',
      );
    });

    test('getDioError_noUserAuthzText_saysSignedOut', () async {
      // Arrange: a request that left the client after logout
      final error = response({
        'errors': 'User [No User] is not authorized for View on REST Path',
      }, status: 403);
      // Act + Assert
      expect(
        await getDioError(error),
        'You have been signed out, please log in again.',
      );
    });

    test('getDioError_errorCodeOnly_reportsTheCode', () async {
      expect(
        await getDioError(response({'errorCode': 500})),
        'Error code: 500',
      );
    });

    test('getDioError_htmlBody_isAGenericServerError', () async {
      expect(
        await getDioError(response('<html>Bad gateway</html>', status: 502)),
        'Server error occurred',
      );
    });

    test('getDioError_emptyErrors_fallsBackToConnectionError', () async {
      expect(
        await getDioError(response({'errors': ''})),
        'Server Connection error',
      );
    });

    test('getDioError_loginKeyInvalid_clearsKeyAndAsksToLogin', () async {
      // Arrange
      SharedPreferences.setMockInitialValues({'apiKey': 'stale'});
      // Act
      final message = await getDioError(
        response({'errors': 'Login key not valid'}, status: 401),
      );
      // Assert
      expect(message, 'Login key expired, please login again');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('apiKey'), isNull);
    });
  });

  group('getDioError network errors', () {
    final cases = {
      DioExceptionType.connectionError: 'Connection error',
      DioExceptionType.receiveTimeout: 'Request timeout',
      DioExceptionType.connectionTimeout: 'Connection timeout',
      DioExceptionType.sendTimeout: 'Send timeout',
      DioExceptionType.cancel: 'Request cancelled',
      DioExceptionType.unknown: 'Network error',
    };
    for (final MapEntry(key: type, value: text) in cases.entries) {
      test('getDioError_${type.name}_says$text', () async {
        expect(await getDioError(noResponse(type)), text);
      });
    }
  });

  group('getDioError other errors', () {
    test('getDioError_formatException_saysInvalidFormat', () async {
      expect(
        await getDioError(const FormatException('bad')),
        'Invalid data format',
      );
    });

    test('getDioError_anythingElse_usesToString', () async {
      expect(await getDioError(StateError('boom')), 'Bad state: boom');
    });
  });
}
