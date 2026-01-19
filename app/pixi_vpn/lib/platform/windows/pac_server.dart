import 'dart:io';

class PacServer {
  HttpServer? _server;
  Uri? _pacUrl;

  Uri? get pacUrl => _pacUrl;

  Future<Uri> start({required int proxyPort}) async {
    if (_server != null) {
      return _pacUrl!;
    }

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    _pacUrl = Uri(
      scheme: 'http',
      host: '127.0.0.1',
      port: server.port,
      path: '/proxy.pac',
    );

    server.listen((request) {
      if (request.uri.path != '/proxy.pac') {
        request.response.statusCode = HttpStatus.notFound;
        request.response.close();
        return;
      }
      final content = _buildPac(proxyPort);
      request.response.headers.contentType =
          ContentType('application', 'x-ns-proxy-autoconfig');
      request.response.write(content);
      request.response.close();
    });

    return _pacUrl!;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _pacUrl = null;
  }

  String _buildPac(int proxyPort) {
    return '''function FindProxyForURL(url, host) {
  if (isPlainHostName(host)) return "DIRECT";
  if (dnsDomainIs(host, "localhost")) return "DIRECT";
  if (isInNet(host, "127.0.0.0", "255.0.0.0")) return "DIRECT";
  if (isInNet(host, "10.0.0.0", "255.0.0.0")) return "DIRECT";
  if (isInNet(host, "192.168.0.0", "255.255.0.0")) return "DIRECT";
  if (isInNet(host, "172.16.0.0", "255.240.0.0")) return "DIRECT";
  return "PROXY 127.0.0.1:$proxyPort; DIRECT";
}
''';
  }
}
