import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/models/proxy_node.dart';

class WindowsTrayService with TrayListener {
  WindowsTrayService({
    required this.onToggleConnection,
    required this.onExit,
    required this.onSelectNode,
  });

  final Future<void> Function() onToggleConnection;
  final Future<void> Function() onExit;
  final Future<void> Function(ProxyNode node) onSelectNode;

  List<ProxyNode> _nodes = const [];
  ProxyNode? _current;
  bool _isConnected = false;
  Timer? _messageTimer;

  Future<void> init() async {
    final iconPath = await _ensureTrayIcon();
    await trayManager.setIcon(iconPath);
    await trayManager.setToolTip('TSVPN');
    await _updateMenu();
    trayManager.addListener(this);
  }

  Future<void> update({
    required List<ProxyNode> nodes,
    required ProxyNode? current,
    required bool isConnected,
  }) async {
    _nodes = nodes;
    _current = current;
    _isConnected = isConnected;
    await _updateMenu();
  }

  Future<void> dispose() async {
    trayManager.removeListener(this);
    _messageTimer?.cancel();
  }

  @override
  void onTrayIconMouseDown() async {
    final isVisible = await windowManager.isVisible();
    if (isVisible) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final key = menuItem.key ?? '';
    if (key == 'toggle') {
      onToggleConnection();
      return;
    }
    if (key == 'show') {
      windowManager.show();
      windowManager.focus();
      return;
    }
    if (key == 'exit') {
      onExit();
      return;
    }
    if (key.startsWith('node:')) {
      final id = key.substring('node:'.length);
      final node = _nodes.firstWhere(
        (n) => n.id == id,
        orElse: () => _current ?? _nodes.first,
      );
      onSelectNode(node);
    }
  }

  Future<void> _updateMenu() async {
    final items = <MenuItem>[
      MenuItem(
        key: 'toggle',
        label: _isConnected ? 'Disconnect' : 'Connect',
      ),
      const MenuItem.separator(),
    ];

    final nodeItems = _nodes.take(5).map((node) {
      final latency = node.latencyMs != null ? ' ${node.latencyMs}ms' : '';
      final label = '${node.displayName}$latency';
      return MenuItem(key: 'node:${node.id}', label: label);
    }).toList();

    if (nodeItems.isNotEmpty) {
      items.addAll(nodeItems);
      items.add(const MenuItem.separator());
    }

    items.addAll([
      MenuItem(key: 'show', label: 'Show'),
      MenuItem(key: 'exit', label: 'Exit'),
    ]);

    await trayManager.setContextMenu(Menu(items: items));
  }

  Future<void> showMessage(String message) async {
    _messageTimer?.cancel();
    await trayManager.setToolTip('TSVPN - $message');
    _messageTimer = Timer(const Duration(seconds: 5), () async {
      await trayManager.setToolTip('TSVPN');
    });
  }

  Future<String> _ensureTrayIcon() async {
    final supportDir = await getApplicationSupportDirectory();
    final iconDir = Directory('${supportDir.path}\\tray');
    await iconDir.create(recursive: true);
    final iconFile = File('${iconDir.path}\\tray.ico');
    if (await iconFile.exists()) {
      return iconFile.path;
    }

    final data = await rootBundle.load('assets/windows/tray.ico');
    await iconFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return iconFile.path;
  }
}
