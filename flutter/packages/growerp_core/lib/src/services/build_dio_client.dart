import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// https://kamaravichow.medium.com/caching-with-dio-hive-in-flutter-e630ac5fc777
Future<Dio> buildDioClient(
    {Duration timeout = const Duration(seconds: 15),
    String? overrideUrl}) async {
  bool android = false;
  try {
    if (Platform.isAndroid) {
      android = true;
    }
    // ignore: empty_catches
  } catch (e) {}

  String databaseUrl = GlobalConfiguration().get('databaseUrl');
  String databaseUrlDebug = GlobalConfiguration().get('databaseUrlDebug');

  final dio = Dio()
    ..options = BaseOptions(
        baseUrl: overrideUrl != null
            ? '$overrideUrl/'
            : kReleaseMode
                ? '$databaseUrl/'
                : databaseUrlDebug.isNotEmpty
                    ? '$databaseUrlDebug/'
                    : android == true
                        ? 'http://10.0.2.2:8080/'
                        : 'http://localhost:8080/')
    ..options.connectTimeout = const Duration(seconds: 5)
    ..options.receiveTimeout = timeout
    ..httpClientAdapter;

  //dio.options.headers['Content-Type'] = 'application/json; charset=UTF-8';
  // suppress Backend warning in debug mode.
  //if (!kReleaseMode) {
  //  dio.options.headers['X-Real-IP'] = dio.options.baseUrl;
  //}
  dio.options.responseType = ResponseType.plain;

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  dio.interceptors.add(KeyInterceptor(prefs));

  dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
      error: true,
      compact: true,
      maxWidth: 133));

  logger.i("accessing backend at ${dio.options.baseUrl}");

  return dio;
}

class KeyInterceptor extends Interceptor {
  KeyInterceptor(this.prefs);

  final SharedPreferences prefs;
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['noApiKey'] == null) {
      options.headers['api_key'] = prefs.getString('apiKey');

      if (options.method != 'GET') {
        options.headers['moquiSessionToken'] =
            prefs.getStringList('moquiSessionToken');
      }
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    await prefs.setStringList(
        'moquiSessionToken', response.headers['moquiSessionToken'] ?? []);

    //  response.headers.removeAll('set-cookie');

    return super.onResponse(response, handler);
  }
}
