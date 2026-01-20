import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tray_manager/tray_manager.dart';

import '../../core/models/proxy_node.dart';

enum TrayActionType { toggleConnection, showWindow, exitApp, selectNode, toggleWindow }

class TrayAction {
  final TrayActionType type;
  final ProxyNode? node;

  const TrayAction(this.type, {this.node});
}

class WindowsTrayService with TrayListener {
  WindowsTrayService();

  List<ProxyNode> _nodes = const [];
  ProxyNode? _current;
  bool _isConnected = false;
  Timer? _messageTimer;
  final StreamController<TrayAction> _actions =
      StreamController<TrayAction>.broadcast();

  Stream<TrayAction> get actions => _actions.stream;

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
    String? toolTip,
  }) async {
    _nodes = nodes;
    _current = current;
    _isConnected = isConnected;
    await _updateMenu();
    if (toolTip != null) {
      await trayManager.setToolTip(toolTip);
    }
  }

  Future<void> dispose() async {
    trayManager.removeListener(this);
    _messageTimer?.cancel();
    await _actions.close();
  }

  @override
  void onTrayIconMouseDown() async {
    _actions.add(const TrayAction(TrayActionType.toggleWindow));
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    final key = menuItem.key ?? '';
    if (key == 'toggle') {
      _actions.add(const TrayAction(TrayActionType.toggleConnection));
      return;
    }
    if (key == 'show') {
      _actions.add(const TrayAction(TrayActionType.showWindow));
      return;
    }
    if (key == 'exit') {
      _actions.add(const TrayAction(TrayActionType.exitApp));
      return;
    }
    if (key.startsWith('node:')) {
      final id = key.substring('node:'.length);
      final node = _nodes.firstWhere(
        (n) => n.id == id,
        orElse: () => _current ?? _nodes.first,
      );
      _actions.add(TrayAction(TrayActionType.selectNode, node: node));
    }
  }

  Future<void> _updateMenu() async {
    final items = <MenuItem>[
      MenuItem(
        key: 'toggle',
        label: _isConnected ? '断开' : '连接',
      ),
      MenuItem.separator(),
    ];

    final nodeItems = _nodes.take(5).map((node) {
      final latency = node.latencyMs != null ? ' ${node.latencyMs}ms' : '';
      final label = '${node.displayName}$latency';
      return MenuItem(key: 'node:${node.id}', label: label);
    }).toList();

    if (nodeItems.isNotEmpty) {
      items.addAll(nodeItems);
      items.add(MenuItem.separator());
    }

    items.addAll([
      MenuItem(key: 'show', label: '打开主窗口'),
      MenuItem(key: 'exit', label: '退出'),
    ]);

    await trayManager.setContextMenu(Menu(items: items));
  }

  Future<void> showMessage(String message) async {
    _messageTimer?.cancel();
    await trayManager.setToolTip('TSVPN · $message');
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
