import 'dart:async';
import 'dart:io';

class NetworkMonitor {
  NetworkMonitor({
    this.interval = const Duration(seconds: 4),
  });

  final Duration interval;
  final StreamController<bool> _controller =
      StreamController<bool>.broadcast();
  Timer? _timer;
  bool _lastStatus = true;

  Stream<bool> get statusStream => _controller.stream;

  Future<void> start() async {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _check());
    await _check();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  Future<void> _check() async {
    final available = await _probe();
    if (available != _lastStatus) {
      _lastStatus = available;
      _controller.add(available);
    }
  }

  Future<bool> _probe() async {
    try {
      final socket = await Socket.connect(
        '1.1.1.1',
        53,
        timeout: const Duration(milliseconds: 500),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }
}
