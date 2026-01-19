import 'package:flutter_v2ray_client/flutter_v2ray.dart';

class AndroidVpnService {
  final void Function(V2RayStatus status) onStatusChanged;
  late final V2ray _v2ray;

  AndroidVpnService({required this.onStatusChanged}) {
    _v2ray = V2ray(onStatusChanged: onStatusChanged);
  }

  void initialize() {
    _v2ray.initialize(
      notificationIconResourceType: 'drawable',
      notificationIconResourceName: 'ic_notification',
    );
  }

  Future<bool> requestPermission() async {
    return _v2ray.requestPermission();
  }

  void start({
    required String remark,
    required String config,
    bool proxyOnly = false,
  }) {
    _v2ray.startV2Ray(
      remark: remark,
      config: config,
      proxyOnly: proxyOnly,
      bypassSubnets: null,
      blockedApps: null,
    );
  }

  Future<void> stop() async {
    await _v2ray.stopV2Ray();
  }
}
