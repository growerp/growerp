import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:growerp_models/src/logger.dart';
import 'package:hive/hive.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

/// https://kamaravichow.medium.com/caching-with-dio-hive-in-flutter-e630ac5fc777
Future<Dio> buildDioClient(String? base,
    {Duration timeout = const Duration(seconds: 5),
    bool miniLog = false}) async {
  bool android = false;
  try {
    if (Platform.isAndroid) {
      android = true;
    }
  } catch (e) {}

  final dio = Dio()
    ..options = BaseOptions(
        baseUrl: base == null
            ? (android == true)
                ? 'http://10.0.2.2:8080/'
                : 'http://localhost:8080/'
            : base)
    ..options.connectTimeout = const Duration(seconds: 5)
    ..options.receiveTimeout = timeout
    ..httpClientAdapter;

  //dio.options.headers['Content-Type'] = 'application/json; charset=UTF-8';
  dio.options.responseType = ResponseType.plain;

  var box = await Hive.openBox('growerp');
  dio.interceptors.add(KeyInterceptor(box));

  dio.interceptors.add(PrettyDioLogger(
      requestHeader: !miniLog,
      requestBody: !miniLog,
      responseBody: !miniLog,
      responseHeader: !miniLog,
      error: true,
      compact: true,
      maxWidth: 133));

  logger.i("accessing backend at ${dio.options.baseUrl}");

  return dio;
}

class KeyInterceptor extends Interceptor {
  KeyInterceptor(this._box);

  Box? _box;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['noApiKey'] == null) {
      options.headers['api_key'] = await _box?.get('apiKey');
      if (options.method != 'GET') {
        options.headers['moquiSessionToken'] =
            await _box?.get('moquiSessionToken');
      }
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    await _box?.put('moquiSessionToken', response.headers['moquiSessionToken']);

    //  response.headers.removeAll('set-cookie');

    return super.onResponse(response, handler);
  }
}
