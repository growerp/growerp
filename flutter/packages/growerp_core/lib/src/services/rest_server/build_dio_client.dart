import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

Future<Dio> buildDioClient(String base, String classificationId) async {
  final dio = Dio()..options = BaseOptions(baseUrl: base);

  dio.interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 133));

  var box = await Hive.openBox('growerp');
  String apiKey = box.get('apiKey') ?? '';
  print("===1== id: $classificationId key: $apiKey");
  dio.interceptors.add(AppendApiKeyInterceptor(classificationId, apiKey));

  return dio;
}

class AppendApiKeyInterceptor extends Interceptor {
  AppendApiKeyInterceptor(this._classificationId, this._apiKey);

  final String _classificationId;
  final String _apiKey;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print("===2== id: $_classificationId key: $_apiKey");
    options.extra['classificationId'] = _classificationId;
    print("====extra: ${options.extra}");
    if (options.headers['requireApiKey'] == true) {
      options.headers['api_key'] = _apiKey;
    }

    return super.onRequest(options, handler);
  }
}
