import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

Future<Dio> buildDioClient(String base) async {
  final dio = Dio()..options = BaseOptions(baseUrl: base);

  dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 133));

  dio.options.headers["content-type"] = "application/json";

  var box = await Hive.openBox('growerp');
  dio.interceptors.add(AppendApiKeyInterceptor(box));

  return dio;
}

class AppendApiKeyInterceptor extends Interceptor {
  AppendApiKeyInterceptor(this._box);

  Box? _box;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
//    print(
//        "=====interceptor key: ${_box?.get('apiKey')} ${options.headers['requireApiKey']}");
    if (options.headers['requireApiKey'] == true) {
      String? apiKey = await _box?.get('apiKey');
      if (apiKey != null) options.headers['api_key'] = apiKey;
    }
    options.headers['Access-Control-Allow-Origin'] = '*';

    return super.onRequest(options, handler);
  }
}
