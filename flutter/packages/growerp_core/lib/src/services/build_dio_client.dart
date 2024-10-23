import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:global_configuration/global_configuration.dart';
//import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:hive/hive.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

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

  var box = await Hive.openBox('growerp');
  dio.interceptors.add(KeyInterceptor(box));
  // https://pub.dev/packages/dio_cache_interceptor
  dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
      error: true,
      compact: true,
      maxWidth: 133));
/*
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
*/
//  dio.interceptors.add(KeyDioCacheInterceptor(options: customCacheOptions));

  logger.i("accessing backend at ${dio.options.baseUrl}");

  return dio;
}

class KeyDioCacheInterceptor extends DioCacheInterceptor {
  KeyDioCacheInterceptor({CacheOptions? customCacheOptions})
      : super(options: customCacheOptions ?? defaultCacheOptions);

  static get defaultCacheOptions => null;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    @override
    CacheOptions cacheOptions =
        (CacheOptions.fromExtra(options) ?? options) as CacheOptions;

    if (options.extra['noCache'] == true) {
      cacheOptions = cacheOptions.copyWith(policy: CachePolicy.noCache);
    }
    return super.onRequest(options, handler);
  }
}

class KeyInterceptor extends Interceptor {
  KeyInterceptor(this._box);

  final Box? _box;

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
