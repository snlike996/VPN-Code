class ProxyNode {
  final String id;
  final String type;
  final String name;
  final String raw;
  final String? host;
  final int? port;
  int? latencyMs;
  int? tcpMs;
  int? tlsMs;
  bool available;
  DateTime? testedAt;

  ProxyNode({
    required this.id,
    required this.type,
    required this.name,
    required this.raw,
    this.host,
    this.port,
    this.latencyMs,
    this.tcpMs,
    this.tlsMs,
    this.available = false,
    this.testedAt,
  });

  String get displayName {
    if (name.isNotEmpty) {
      return name;
    }
    if (host != null && host!.isNotEmpty) {
      return port != null ? '$host:$port' : host!;
    }
    return raw;
  }
}
