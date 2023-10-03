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
      maxWidth: 90));

  var box = await Hive.openBox('growerp');
  String _apiKey = box.get('apiKey') ?? '';

  dio.interceptors.add(AppendApiKeyInterceptor(_apiKey));
  return dio;
}

class AppendApiKeyInterceptor extends Interceptor {
  AppendApiKeyInterceptor(this._apiKey);

  final String _apiKey;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['api_key'] = _apiKey;

    return super.onRequest(options, handler);
  }
}
