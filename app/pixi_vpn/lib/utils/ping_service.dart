import 'dart:async';
import 'dart:developer';
import 'package:dio/dio.dart';

class PingService {
  final Dio _dio;
  
  // 统一的测速地址
  static const String _speedTestUrl = 'https://www.google.com/generate_204';

  PingService({Dio? dio}) : _dio = dio ?? Dio();

  /// 测试网络延迟
  /// 原理: Flutter HTTP → VPN Tunnel → 测速服务器
  /// 使用 Google generate_204 端点进行测速
  /// 返回延迟（毫秒），失败返回null
  Future<int?> pingSpeed() async {
    try {
      final stopwatch = Stopwatch()..start();
      
      // 使用 GET 请求测速，3秒超时
      await _dio.get(
        _speedTestUrl,
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
          followRedirects: false,
          validateStatus: (status) => status != null && status == 204,
        ),
      );
      
      stopwatch.stop();
      
      final latency = stopwatch.elapsedMilliseconds;
      log('Speed test successful: ${latency}ms');
      
      return latency;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        log('Speed test timeout (3s)');
        return null;
      }
      log('Speed test error: ${e.message}');
      return null;
    } catch (e) {
      log('Unexpected speed test error: $e');
      return null;
    }
  }
}
