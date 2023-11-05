import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:growerp_models/src/logger.dart';
import 'package:hive/hive.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:path_provider/path_provider.dart';

Future<Dio> buildDioClient(String? base,
    {Duration timeout = const Duration(seconds: 5)}) async {
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
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
      error: true,
      compact: true,
      maxWidth: 133));

  var cacheDir = await getTemporaryDirectory();
  var cacheStore = HiveCacheStore(
    cacheDir.path,
    hiveBoxName: "growerpCache",
  );

  var customCacheOptions = CacheOptions(
    store: cacheStore,
    policy: CachePolicy.forceCache,
    priority: CachePriority.high,
    maxStale: const Duration(minutes: 5),
    hitCacheOnErrorExcept: [401, 404],
    keyBuilder: (request) {
      return request.uri.toString();
    },
    allowPostMethod: false,
  );

  dio.interceptors.add(DioCacheInterceptor(options: customCacheOptions));

  logger.i("accessing backend at ${dio.options.baseUrl}");

  return dio;
}

class KeyInterceptor extends Interceptor {
  KeyInterceptor(this._box);

  Box? _box;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra['requireApiKey'] == true) {
      options.headers['api_key'] = await _box?.get('apiKey');
    }

    //if (options.method != 'GET') {
    //  options.headers['moquisessiontoken'] =
    //      await _box?.get('moquiSessionToken');
    //}

    return super.onRequest(options, handler);
  }

  //@override
  //void onResponse(Response response, ResponseInterceptorHandler handler) async {
  //  await _box?.put('moquiSessionToken', response.headers['moquisessiontoken']);

  //  response.headers.removeAll('set-cookie');

  //  return super.onResponse(response, handler);
  //}
}
