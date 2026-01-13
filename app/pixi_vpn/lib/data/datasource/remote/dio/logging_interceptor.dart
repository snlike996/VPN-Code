import 'package:dio/dio.dart';

class LoggingInterceptor extends InterceptorsWrapper{

  int maxCharactersPerLine = 200;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // TODO: implement onRequest
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // TODO: implement onResponse
    String responseAsString = response.data.toString();

    if (responseAsString.length > maxCharactersPerLine) {
      int iterations = (responseAsString.length / maxCharactersPerLine).floor();
      for (int i = 0; i <= iterations; i++) {
        int endingIndex = i * maxCharactersPerLine + maxCharactersPerLine;
        if (endingIndex > responseAsString.length) {
          endingIndex = responseAsString.length;
        }
      }
    } else {
    }
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException? err, ErrorInterceptorHandler handler) {
    // TODO: implement onError
    super.onError(err!, handler);
  }


}