enum NodeHealth {
  unknown,
  testing,
  excellent,
  good,
  fair,
  poor,
  unavailable,
}

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
  String? testError;
  DateTime? testedAt;
  NodeHealth health;
  String? lastError;
  DateTime? lastTestAt;

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
    this.testError,
    this.testedAt,
    this.health = NodeHealth.unknown,
    this.lastError,
    this.lastTestAt,
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
