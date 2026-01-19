import '../models/proxy_node.dart';

class NodeSelector {
  static ProxyNode? pickBest(List<ProxyNode> nodes) {
    if (nodes.isEmpty) {
      return null;
    }
    final sorted = nodes.toList()
      ..sort((a, b) {
        if (a.available != b.available) {
          return a.available ? -1 : 1;
        }
        final aLatency = a.latencyMs;
        final bLatency = b.latencyMs;
        if (aLatency == null && bLatency == null) {
          return 0;
        }
        if (aLatency == null) {
          return 1;
        }
        if (bLatency == null) {
          return -1;
        }
        return aLatency.compareTo(bLatency);
      });

    return sorted.first;
  }
}
