import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logging_interceptor.dart';

class DioClient {
  final String baseUrl;
  final LoggingInterceptor loggingInterceptor;
  final SharedPreferences sharedPreferences;

  Dio? dio;
  String? token;
  String? countryCode;

  // Add your allowed SHA256 fingerprints here (uppercase, no colons)
  static const List<String> allowedSha256Fingerprints = [
    'AF6C8DA0BD702B49777DC817BA8CF2553FD73C8ABDEB6FE79DBDF5CB768B5433',
    '47A0FA0A49AEA6C6A29A689E5F707B48463204BE7E29524292AB3B8BD740D4D7',
  ];

  DioClient(
      this.baseUrl,
      Dio? dioC, {
        required this.loggingInterceptor,
        required this.sharedPreferences,
      }) {
    dio = dioC ?? Dio();

    // Setup Dio with custom HttpClientAdapter for SSL pinning
    // Skip on macOS/Windows to rely on system store and avoid manual handshake failures
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      dio!.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final httpClient = HttpClient();

          httpClient.badCertificateCallback =
              (X509Certificate cert, String host, int port) {
            // Calculate SHA256 fingerprint of the certificate
            final der = cert.der;
            final sha256 = sha256convert(der);

            if (kDebugMode) {
              print('Certificate SHA256: $sha256');
            }

            // Compare against allowed fingerprints
            if (allowedSha256Fingerprints.contains(sha256)) {
              return true; // Certificate is trusted
            }

            // Not trusted details
             throw HandshakeException('SSL Pinning failed. Host: $host, Fingerprint: $sha256');
          };

          return httpClient;
        },
      );
    }

    dio!
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = const Duration(seconds: 60)
      ..options.receiveTimeout = const Duration(seconds: 60)
      ..options.headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

    dio!.interceptors.add(loggingInterceptor);
  }

  // Helper to calculate the SHA256 fingerprint string from DER bytes
  static String sha256convert(List<int> derBytes) {
    final digest = sha256.convert(derBytes);
    // Convert digest to uppercase hex string without colons
    return digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
  }

  void updateHeader(String token, String countryCode) {
    this.token = token;
    this.countryCode = countryCode;
    dio?.options.headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ... Your existing get/post/put/delete methods unchanged ...
  Future<Response> get(
      String uri, {
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      return await dio!.get(
        uri,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(
      String uri, {
        data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      return await dio!.post(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(
      String uri, {
        data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
      }) async {
    try {
      return await dio!.put(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(
      String uri, {
        data,
        Map<String, dynamic>? queryParameters,
        Options? options,
        CancelToken? cancelToken,
      }) async {
    try {
      return await dio!.delete(
        uri,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      rethrow;
    }
  }
}
