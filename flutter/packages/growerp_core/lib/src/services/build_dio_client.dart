import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/foundation.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:growerp_models/growerp_models.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Backend port can be overridden at compile time using:
/// --dart-define=BACKEND_PORT=8080
const String _backendPort = String.fromEnvironment(
  'BACKEND_PORT',
  defaultValue: '8080',
);

/// Global in-memory cache store shared across all Dio instances.
///
/// Uses [MemCacheStore] which is a volatile LRU cache — data is lost
/// when the app restarts, which is the correct behaviour for session-scoped
/// REST data.
MemCacheStore? _cacheStore;

/// Returns the global [MemCacheStore] used for REST caching.
///
/// Creates one lazily if it doesn't exist yet.
MemCacheStore getRestCacheStore() {
  _cacheStore ??= MemCacheStore();
  return _cacheStore!;
}

/// Clears the entire REST cache.
///
/// Call this on logout or when session data becomes invalid.
Future<void> clearRestCache() async {
  await _cacheStore?.clean();
}

/// Default cache duration used when no configuration value is provided.
const int _defaultCacheMaxStaleMinutes = 10;

/// Builds a [Dio] client configured with authentication, logging, and
/// HTTP response caching.
///
/// The cache uses [MemCacheStore] (in-memory LRU) with the following
/// behaviour:
///  - Only **GET** requests are cached.
///  - Cached responses are served for up to `cacheMaxStaleMinutes` minutes
///    (configurable via `app_settings.json`, default 10 min).
///  - Any successful **POST / PATCH / DELETE** response automatically
///    clears the entire cache so that subsequent GETs fetch fresh data.
///  - The cache can be cleared manually via [clearRestCache].
Future<Dio> buildDioClient({
  Duration timeout = const Duration(seconds: 60),
  String? overrideUrl,
}) async {
  bool android = false;
  try {
    if (Platform.isAndroid) {
      android = true;
    }
    // ignore: empty_catches
  } catch (e) {}

  String? databaseUrl = GlobalConfiguration().get('databaseUrl');
  String? databaseUrlDebug = GlobalConfiguration().get('databaseUrlDebug');

  String baseUrl;
  if (overrideUrl != null) {
    baseUrl = overrideUrl;
  } else if (kReleaseMode) {
    baseUrl = databaseUrl ?? 'https://backend.growerp.com';
  } else if (databaseUrlDebug != null && databaseUrlDebug.isNotEmpty) {
    baseUrl = databaseUrlDebug;
  } else {
    baseUrl = android == true
        ? 'http://10.0.2.2:$_backendPort'
        : 'http://localhost:$_backendPort';
  }

  // Ensure trailing slash only once
  if (!baseUrl.endsWith('/')) {
    baseUrl = '$baseUrl/';
  }

  // Get timeout values from configuration
  int connectTimeoutSeconds;
  int receiveTimeoutSeconds;

  if (kReleaseMode) {
    connectTimeoutSeconds =
        GlobalConfiguration().get('connectTimeoutProd') ?? 15;
    receiveTimeoutSeconds =
        GlobalConfiguration().get('receiveTimeoutProd') ?? 60;
  } else {
    connectTimeoutSeconds =
        GlobalConfiguration().get('connectTimeoutTest') ?? 20;
    receiveTimeoutSeconds =
        GlobalConfiguration().get('receiveTimeoutTest') ?? 120;
  }

  // Use provided timeout duration if it's longer than config, otherwise use config
  final configReceiveTimeout = Duration(seconds: receiveTimeoutSeconds);
  final effectiveReceiveTimeout =
      timeout.inSeconds > configReceiveTimeout.inSeconds
      ? timeout
      : configReceiveTimeout;

  final dio = Dio()
    ..options = BaseOptions(baseUrl: baseUrl)
    ..options.connectTimeout = Duration(seconds: connectTimeoutSeconds)
    ..options.receiveTimeout = effectiveReceiveTimeout
    ..httpClientAdapter;

  dio.options.responseType = ResponseType.plain;

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // 1. API key / session token interceptor (must run before cache)
  dio.interceptors.add(KeyInterceptor(prefs));

  // 2. HTTP cache interceptor — caches GET responses in memory
  //    Set cacheMaxStaleMinutes to 0 in app_settings.json to disable caching.
  final int cacheMaxStaleMinutes =
      GlobalConfiguration().get('cacheMaxStaleMinutes') ??
      _defaultCacheMaxStaleMinutes;

  if (cacheMaxStaleMinutes > 0) {
    final cacheOptions = CacheOptions(
      store: getRestCacheStore(),
      policy: CachePolicy.request,
      hitCacheOnErrorCodes: [500, 502, 503],
      hitCacheOnNetworkFailure: true,
      maxStale: Duration(minutes: cacheMaxStaleMinutes),
      priority: CachePriority.normal,
      allowPostMethod: false,
    );

    dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));

    // 3. Cache invalidation — clear cache after successful mutations
    dio.interceptors.add(CacheInvalidationInterceptor(getRestCacheStore()));

    logger.i('REST cache enabled (maxStale: $cacheMaxStaleMinutes min)');
  } else {
    logger.i('REST cache disabled (cacheMaxStaleMinutes = 0)');
  }

  // 4. Pretty logger (last, so it logs the final request/response)
  dio.interceptors.add(
    PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: true,
      error: true,
      compact: true,
      maxWidth: 133,
    ),
  );

  logger.i("accessing backend at ${dio.options.baseUrl}");

  return dio;
}

/// Interceptor that injects the API key and moqui session token.
class KeyInterceptor extends Interceptor {
  KeyInterceptor(this.prefs);

  final SharedPreferences prefs;
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra['noApiKey'] == null) {
      options.headers['api_key'] = prefs.getString('apiKey');

      if (options.method != 'GET') {
        options.headers['moquiSessionToken'] = prefs.getString(
          'moquiSessionToken',
        );
      }
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    await prefs.setString(
      'moquiSessionToken',
      response.headers['moquiSessionToken']?.first ?? '',
    );

    return super.onResponse(response, handler);
  }
}

/// Interceptor that clears the REST cache after any successful mutating
/// request (POST, PATCH, PUT, DELETE).
///
/// This ensures that subsequent GET requests always return fresh data
/// after the user creates, updates, or deletes a resource.
class CacheInvalidationInterceptor extends Interceptor {
  CacheInvalidationInterceptor(this._cacheStore);

  final MemCacheStore _cacheStore;

  static const _mutatingMethods = {'POST', 'PATCH', 'PUT', 'DELETE'};

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (_mutatingMethods.contains(response.requestOptions.method)) {
      await _cacheStore.clean();
      logger.d(
        'REST cache cleared after ${response.requestOptions.method} '
        '${response.requestOptions.path}',
      );
    }
    return super.onResponse(response, handler);
  }
}
