import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../../controller/auth_controller.dart';
import '../../controller/profile_controller.dart';
import '../../controller/v2ray_vpn_controller.dart';
import '../../core/models/country_item.dart';
import '../../core/connection/connection_controller.dart';
import '../../core/models/proxy_node.dart';
import '../../core/selector/node_selector.dart';
import '../../core/speedtest/windows_real_tester.dart';
import '../../utils/app_colors.dart';
import '../../platform/windows/admin_check.dart';
import '../../platform/windows/autostart.dart';
import '../../platform/windows/connection_adapter.dart';
import '../../platform/windows/system_proxy.dart';
import '../../platform/windows/tray_service.dart';
import '../../platform/windows/privilege_helper.dart';
import 'dialogs/login_dialog.dart';
import 'dialogs/profile_dialog.dart';
import 'dialogs/settings_dialog.dart';
import 'windows_app.dart';

class WindowsHomeScreen extends StatefulWidget {
  final ConnectionController controller;
  final WindowsConnectionAdapter adapter;
  final WindowsLaunchOptions launchOptions;

  const WindowsHomeScreen({
    super.key,
    required this.controller,
    required this.adapter,
    required this.launchOptions,
  });

  @override
  State<WindowsHomeScreen> createState() => _WindowsHomeScreenState();
}

class _WindowsHomeScreenState extends State<WindowsHomeScreen>
    with WindowListener {
  late final V2rayVpnController _controller;
  late final WindowsTrayService _trayService;
  CountryItem? _selectedCountry;
  ProxyNode? _selectedNode;
  bool _isTesting = false;
  bool _closeToTray = true;
  bool _autoStart = false;
  bool _dnsProtect = true;
  bool _autoConnect = false;
  bool _autoConnectRetry = false;
  ProxyMode _proxyMode = ProxyMode.pac;
  bool _restoreProxy = true;
  String _autoConnectCountryMode = 'last';
  String? _fixedCountryCode;
  bool _silentLaunch = false;
  Timer? _autoConnectTimer;
  StreamSubscription<String>? _notificationSubscription;
  StreamSubscription<String>? _configNoticeSubscription;
  bool _lastConnectFailed = false;
  int _reconnectFailureCount = 0;
  bool _isLoggedIn = false;
  String _userLabel = '登录';
  Timer? _testDebounce;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<V2rayVpnController>();
    _controller.getCountries();
    _refreshAuthState();
    _silentLaunch = widget.launchOptions.silent || widget.launchOptions.autoConnect;

    _trayService = WindowsTrayService(
      onToggleConnection: _toggleConnection,
      onExit: _exitApp,
      onSelectNode: _selectNode,
    );
    Future<void>.microtask(_trayService.init);

    windowManager.addListener(this);
    windowManager.setPreventClose(true);

    widget.controller.status.addListener(_syncTrayState);
    widget.controller.status.addListener(_handleStatusChange);
    _notificationSubscription =
        widget.controller.notifications.listen(_handleNotification);
    _configNoticeSubscription =
        widget.adapter.configNotices.listen(_handleConfigNotice);
    _loadSettings();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!WindowsPrivilege.isAdmin()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Run as administrator to enable VPN/TUN.')),
        );
      }
    });
  }

  @override
  void dispose() {
    _testDebounce?.cancel();
    _autoConnectTimer?.cancel();
    _notificationSubscription?.cancel();
    _configNoticeSubscription?.cancel();
    widget.controller.status.removeListener(_syncTrayState);
    widget.controller.status.removeListener(_handleStatusChange);
    windowManager.removeListener(this);
    _trayService.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    if (_closeToTray) {
      await _showTrayHintIfNeeded();
      await windowManager.hide();
    } else {
      await _exitApp();
    }
  }

  Future<void> _exitApp() async {
    await widget.controller.disconnect(userInitiated: true);
    await windowManager.destroy();
  }

  Future<void> _handleEscape() async {
    if (_closeToTray) {
      await _showTrayHintIfNeeded();
      await windowManager.hide();
    } else {
      await _exitApp();
    }
  }

  Future<void> _toggleConnection() async {
    if (widget.controller.status.value == ConnectionStatus.connected ||
        widget.controller.status.value == ConnectionStatus.starting ||
        widget.controller.status.value == ConnectionStatus.reconnecting) {
      await widget.controller.disconnect(userInitiated: true);
      setState(() {
        _lastConnectFailed = false;
      });
      return;
    }
    if (_selectedNode == null) {
      return;
    }
    await _connectSelected();
  }

  void _handleConfigNotice(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _connectSelected() async {
    final node = _selectedNode;
    if (node == null) {
      return;
    }
    if (!_isLoggedIn) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录')),
        );
      }
      return;
    }
    if (node.health == NodeHealth.testing ||
        node.health == NodeHealth.unknown) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('节点测速中，请稍后再试。')),
        );
      }
      return;
    }
    if (node.health == NodeHealth.unavailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              node.lastError == null
                  ? '该节点当前不可用，请稍后重试。'
                  : '该节点当前不可用：${_describeTestError(node.lastError)}',
            ),
          ),
        );
      }
      return;
    }
    if (_dnsProtect && !WindowsAdminCheck.isAdmin()) {
      if (!_silentLaunch) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DNS 防泄漏需要管理员权限。')),
        );
      }
      widget.adapter.vpnManager.dnsProtectionEnabled = false;
    } else {
      widget.adapter.vpnManager.dnsProtectionEnabled = _dnsProtect;
    }
    try {
      _lastConnectFailed = false;
      if (mounted) {
        debugPrint(
          'Connect node id=${node.id} name=${node.displayName} type=${node.type} host=${node.host ?? ''} port=${node.port ?? ''}',
        );
      }
      await widget.controller.connect(node, silent: _silentLaunch);
    } catch (e) {
      _lastConnectFailed = true;
      _reconnectFailureCount += 1;
      if (_reconnectFailureCount >= 2) {
        final switched = _switchToBackupNode();
        if (switched && mounted) {
          _reconnectFailureCount = 0;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已为你切换到备用节点')),
          );
        }
      }
      if (!mounted) {
        return;
      }
      if (!_silentLaunch) {
        final msg = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接失败：$msg')),
        );
      }
    }
  }

  Future<void> _selectCountry(CountryItem country) async {
    setState(() {
      _selectedCountry = country;
      _selectedNode = null;
    });

    await _controller.loadCountryNodes(country.code);
    await _runSpeedTest();
  }

  Future<void> _selectNode(ProxyNode node) async {
    setState(() {
      _selectedNode = node;
    });
    await _trayService.update(
      nodes: _controller.vpnServers,
      current: _selectedNode,
      isConnected: widget.controller.status.value == ConnectionStatus.connected,
      toolTip: 'TSVPN',
    );
    if (widget.controller.status.value == ConnectionStatus.connected) {
      await widget.controller.disconnect(userInitiated: false);
      await _connectSelected();
    }
  }

  void _handleNodeTap(ProxyNode node) {
    setState(() {
      _selectedNode = node;
    });
    if (node.health == NodeHealth.unknown && !_isTesting) {
      _testDebounce?.cancel();
      _testDebounce = Timer(const Duration(milliseconds: 300), () {
        _retestNode(node);
      });
    }
  }

  Future<void> _retestNode(ProxyNode node) async {
    if (_isTesting) {
      return;
    }
    await WindowsRealTester.clearCacheFor([node]);
    await _runSpeedTest();
  }

  Future<void> _copyNodeName(ProxyNode node) async {
    await Clipboard.setData(ClipboardData(text: node.displayName));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制节点名')),
    );
  }

  void _showNodeError(ProxyNode node) {
    final message = node.lastError;
    if (message == null || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无错误信息')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('节点错误原因'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<void> _runSpeedTest({bool force = false}) async {
    if (_controller.vpnServers.isEmpty) {
      return;
    }
    setState(() {
      _isTesting = true;
    });

    try {
      if (force) {
        await WindowsRealTester.clearCacheFor(_controller.vpnServers);
      }
      final sorted = await WindowsRealTester.testAndSort(
        _controller.vpnServers,
        timeout: const Duration(seconds: 5),
      );
      _controller.setVpnServers(sorted);
      _selectedNode ??= NodeSelector.pickBest(sorted);
      await _syncTrayState();
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  Future<void> _syncTrayState() async {
    final nodeName = _selectedNode?.displayName;
    final toolTip = widget.controller.status.value == ConnectionStatus.connected
        ? (nodeName == null ? 'TSVPN 已连接' : 'TSVPN 已连接 · $nodeName')
        : 'TSVPN';
    await _trayService.update(
      nodes: _controller.vpnServers,
      current: _selectedNode,
      isConnected: widget.controller.status.value == ConnectionStatus.connected,
      toolTip: toolTip,
    );
  }

  Future<void> _handleNotification(String message) async {
    if (message.contains('网络中断')) {
      final best = NodeSelector.pickBest(_controller.vpnServers);
      if (best != null && best.id != _selectedNode?.id) {
        setState(() {
          _selectedNode = best;
        });
        widget.controller.updateNode(best);
        _syncTrayState();
      }
    }
    final match = RegExp(r'第(\d+)次').firstMatch(message);
    final attempt = match != null ? int.tryParse(match.group(1) ?? '') : null;
    if (attempt != null && attempt >= 2) {
      final switched = _switchToBackupNode();
      if (switched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已为你切换到备用节点')),
        );
      }
    }
    await _trayService.showMessage(message);
    if (!_silentLaunch && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _handleStatusChange() async {
    if (widget.controller.status.value == ConnectionStatus.connected) {
      _reconnectFailureCount = 0;
      await _persistLastConnected();
      await _syncTrayState();
    }
  }

  Future<void> _persistLastConnected() async {
    final node = _selectedNode;
    final country = _selectedCountry;
    if (node == null || country == null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('win_last_node_raw', node.raw);
    await prefs.setString('win_last_node_fp', _fingerprint(node.raw));
    await prefs.setString('win_last_country', country.code);
    await prefs.setString('win_last_proxy_mode', _proxyMode.name);
    final port = widget.adapter.localProxyPort;
    if (port != null) {
      await prefs.setInt('win_last_proxy_port', port);
    }
  }

  Future<void> _maybeAutoConnect() async {
    if (!_autoConnect || !widget.launchOptions.autoConnect) {
      return;
    }
    if (widget.controller.status.value != ConnectionStatus.idle) {
      return;
    }

    if (_controller.countries.isEmpty) {
      await _controller.getCountries();
    }

    final prefs = await SharedPreferences.getInstance();
    String? targetCountry;
    if (_autoConnectCountryMode == 'fixed' && _fixedCountryCode != null) {
      targetCountry = _fixedCountryCode;
    } else {
      targetCountry = prefs.getString('win_last_country');
    }

    if (targetCountry == null && _controller.countries.isNotEmpty) {
      targetCountry = _controller.countries.first.code;
    }
    if (targetCountry == null) {
      return;
    }

    final match = _controller.countries.firstWhere(
      (c) => c.code == targetCountry,
      orElse: () => _controller.countries.first,
    );

    await _selectCountry(match);

    final candidates = await _selectAutoConnectCandidates();
    if (candidates.isEmpty) {
      return;
    }
    await _autoConnectAttempt(candidates);
  }

  Future<List<ProxyNode>> _selectAutoConnectCandidates() async {
    final prefs = await SharedPreferences.getInstance();
    final lastFingerprint = prefs.getString('win_last_node_fp');
    final lastRaw = prefs.getString('win_last_node_raw');
    final nodes = _controller.vpnServers;
    if (nodes.isEmpty) {
      return [];
    }

    final selected = <ProxyNode>[];
    if (lastFingerprint != null) {
      final match = nodes.firstWhere(
        (n) => _fingerprint(n.raw) == lastFingerprint,
        orElse: () => nodes.first,
      );
      if (!selected.contains(match)) {
        selected.add(match);
      }
    } else if (lastRaw != null) {
      final match = nodes.firstWhere(
        (n) => n.raw == lastRaw,
        orElse: () => nodes.first,
      );
      if (!selected.contains(match)) {
        selected.add(match);
      }
    }

    final best = NodeSelector.pickBest(nodes);
    if (best != null && !selected.contains(best)) {
      selected.add(best);
    }

    for (final node in nodes) {
      if (node.available && !selected.contains(node)) {
        selected.add(node);
      }
      if (selected.length >= 3) {
        break;
      }
    }

    return selected.take(3).toList();
  }

  Future<void> _autoConnectAttempt(List<ProxyNode> candidates) async {
    for (final node in candidates) {
      _selectedNode = node;
      try {
        await widget.controller.connect(node, silent: true);
        return;
      } catch (_) {
        // continue to next
      }
    }

    if (_autoConnectRetry) {
      _autoConnectTimer?.cancel();
      _autoConnectTimer = Timer(const Duration(seconds: 30), () {
        _maybeAutoConnect();
      });
    } else {
      await _trayService.update(
        nodes: _controller.vpnServers,
        current: _selectedNode,
        isConnected: false,
        toolTip: 'TSVPN',
      );
    }
  }

  String _fingerprint(String input) {
    const int fnvPrime = 16777619;
    const int fnvOffset = 0x811c9dc5;
    int hash = fnvOffset;
    for (final byte in input.codeUnits) {
      hash ^= byte;
      hash = (hash * fnvPrime) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.escape): const ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<Intent>(
            onInvoke: (_) {
              _handleEscape();
              return null;
            },
          ),
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('TSVPN · Windows'),
            actions: [
              // 1. Connection status display (read-only)
              _buildConnectionStatusIndicator(),
              const SizedBox(width: 16),
              
              // 2. Login/Profile button
              _buildUserButton(),
              const SizedBox(width: 8),
              
              // 3. Settings button
              _buildSettingsButton(),
              const SizedBox(width: 16),
            ],
          ),
          body: Row(
            children: [
              SizedBox(
                width: 240,
                child: _buildCountryList(),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: _buildNodeList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCountryList() {
    return GetBuilder<V2rayVpnController>(
      builder: (controller) {
        if (controller.isLoadingCountries) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.countriesError != null) {
          return Center(child: Text(controller.countriesError!));
        }
        return ListView.builder(
          itemCount: controller.countries.length,
          itemBuilder: (context, index) {
            final country = controller.countries[index];
            final selected = _selectedCountry?.code == country.code;
            return ListTile(
              selected: selected,
              title: Text(country.name),
              subtitle: Text(country.code.toUpperCase()),
              onTap: () => _selectCountry(country),
            );
          },
        );
      },
    );
  }

  Widget _buildNodeList() {
    return GetBuilder<V2rayVpnController>(
      builder: (controller) {
        if (_selectedCountry == null) {
          return const Center(child: Text('请选择国家以加载节点'));
        }
        if (controller.isLoadingNodes) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.nodesError != null) {
          return Center(child: Text(controller.nodesError!));
        }

        final nodes = controller.vpnServers;
        if (nodes.isEmpty) {
          return const Center(child: Text('暂无节点'));
        }

        final bestNode = NodeSelector.pickBest(nodes);


        return Column(
          children: [
            _buildConnectAction(),
            if (_isTesting)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('测速中…'),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: nodes.length,
                itemBuilder: (context, index) {
                  final node = nodes[index];
                  final isSelected = _selectedNode?.id == node.id;
                  final isUnavailable = node.health == NodeHealth.unavailable;
                  final isTestingNode = node.health == NodeHealth.testing;
                  final best = bestNode?.id == node.id &&
                      node.health != NodeHealth.unavailable;
                  final titleStyle = isUnavailable
                      ? const TextStyle(color: Colors.grey)
                      : null;
                  final errorLabel = _describeTestError(node.lastError);
                  final subtitle = isTestingNode
                      ? const Text('测速中…', style: TextStyle(color: Colors.grey))
                      : isUnavailable
                          ? Tooltip(
                              message: node.lastError == null
                                  ? '该节点当前无法连接，请稍后重试'
                                  : '测速失败：$errorLabel',
                              child: const Text(
                                '不可用',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            )
                          : Text(node.type.toUpperCase());

                  return Opacity(
                    opacity: isUnavailable ? 0.45 : 1,
                    child: InkWell(
                      onTap: () => _handleNodeTap(node),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.appPrimaryColor.withValues(alpha: 0.08)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 56,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.appPrimaryColor
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        node.displayName,
                                        style: titleStyle,
                                      ),
                                    ),
                                    if (best)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.appPrimaryColor
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Text(
                                          '推荐',
                                          style: TextStyle(fontSize: 10),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: subtitle,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _HealthIndicator(node: node),
                                    const SizedBox(width: 6),
                                    PopupMenuButton<String>(
                                      tooltip: '更多',
                                      onSelected: (value) {
                                        if (value == 'retest') {
                                          _retestNode(node);
                                        } else if (value == 'copy') {
                                          _copyNodeName(node);
                                        } else if (value == 'error') {
                                          _showNodeError(node);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'retest',
                                          child: Text('重新测速'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'copy',
                                          child: Text('复制节点名'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'error',
                                          child: Text('查看错误原因'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTrayHintIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('win_seen_tray_hint') ?? false;
    if (seen) {
      return;
    }
    await _trayService.showMessage('TSVPN 已在后台运行，可在右下角托盘中打开');
    await prefs.setBool('win_seen_tray_hint', true);
  }

  bool _switchToBackupNode() {
    final nodes = _controller.vpnServers.where((n) => n.available).toList();
    if (nodes.isEmpty) {
      return false;
    }
    final currentId = _selectedNode?.id;
    final backup = nodes.firstWhere(
      (n) => n.id != currentId,
      orElse: () => nodes.first,
    );
    if (backup.id == currentId) {
      return false;
    }
    setState(() {
      _selectedNode = backup;
    });
    widget.controller.updateNode(backup);
    _syncTrayState();
    return true;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final closeToTray = prefs.getBool('win_close_to_tray') ?? true;
    final dnsProtect = prefs.getBool('win_dns_protect') ?? true;
    final autoStart = await WindowsAutoStart.isAutoStartEnabled();
    final autoConnect = prefs.getBool('win_auto_connect') ?? false;
    final autoConnectRetry = prefs.getBool('win_auto_connect_retry') ?? false;
    final proxyModeName = prefs.getString('win_proxy_mode') ?? ProxyMode.pac.name;
    final restoreProxy = prefs.getBool('win_restore_proxy') ?? true;
    final autoCountryMode = prefs.getString('win_auto_country_mode') ?? 'last';
    final fixedCountryCode = prefs.getString('win_auto_country_code');
    final lastProxyPort = prefs.getInt('win_last_proxy_port');
    if (!mounted) {
      return;
    }
    setState(() {
      _closeToTray = closeToTray;
      _dnsProtect = dnsProtect;
      _autoStart = autoStart;
      _autoConnect = autoConnect;
      _autoConnectRetry = autoConnectRetry;
      _proxyMode =
          ProxyMode.values.firstWhere((e) => e.name == proxyModeName, orElse: () => ProxyMode.pac);
      _restoreProxy = restoreProxy;
      _autoConnectCountryMode = autoCountryMode;
      _fixedCountryCode = fixedCountryCode;
    });
    widget.adapter.vpnManager.dnsProtectionEnabled = _dnsProtect;
    widget.adapter.proxyMode = _proxyMode;
    widget.adapter.restoreProxyOnDisconnect = _restoreProxy;
    if (lastProxyPort != null) {
      widget.adapter.localProxyPort = lastProxyPort;
    }
    await _maybeAutoConnect();
  }

  // ----- Top App Bar Components -----

  Widget _buildConnectionStatusIndicator() {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.controller.networkAvailable,
      builder: (context, isNetworkAvailable, _) {
        return ValueListenableBuilder<ConnectionStatus>(
          valueListenable: widget.controller.status,
          builder: (context, status, _) {
            final isConnected = status == ConnectionStatus.connected;
            final isConnecting = status == ConnectionStatus.starting ||
                status == ConnectionStatus.reconnecting;

            Color color;
            IconData icon;
            String label;

            if (isConnected) {
              color = Colors.green;
              icon = Icons.check_circle;
              final nodeName = _selectedNode?.displayName;
              label = nodeName == null ? '已连接' : '已连接 · $nodeName';
            } else if (isConnecting) {
              color = Colors.orange;
              icon = Icons.autorenew;
              label = status == ConnectionStatus.reconnecting
                  ? (isNetworkAvailable
                      ? '网络波动，正在重连…'
                      : '网络中断，等待恢复…')
                  : '正在连接…';
            } else if (_lastConnectFailed) {
              color = Colors.red;
              icon = Icons.error_outline;
              label = '连接失败';
            } else {
              color = Colors.grey;
              icon = Icons.circle_outlined;
              label = '未连接';
            }

            return Tooltip(
              message: '当前连接状态',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserButton() {
    if (!_isLoggedIn) {
      return TextButton.icon(
        onPressed: _showLoginDialog,
        icon: const Icon(Icons.login, size: 18),
        label: const Text('登录'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.blue,
        ),
      );
    }

    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      tooltip: '个人中心',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.account_circle, size: 20, color: Colors.blue),
            const SizedBox(width: 6),
            Text(
              _userLabel,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person, size: 18),
              SizedBox(width: 8),
              Text('个人中心'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18),
              SizedBox(width: 8),
              Text('退出登录'),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'profile') {
          _showProfileDialog();
        } else if (value == 'logout') {
          _handleLogout();
        }
      },
    );
  }

  Widget _buildSettingsButton() {
    return IconButton(
      tooltip: '设置',
      onPressed: _showSettingsDialog,
      icon: const Icon(Icons.settings),
    );
  }

  // ----- Dialog Handlers -----

  Future<void> _showLoginDialog() async {
    await showDialog(
      context: context,
      builder: (context) => WindowsLoginDialog(
        onLoginSuccess: () {
          // Refresh countries after login
          _controller.getCountries();
          _refreshAuthState();
        },
      ),
    );
  }

  Future<void> _showProfileDialog() async {
    await showDialog(
      context: context,
      builder: (context) => const WindowsProfileDialog(),
    );
    await _refreshAuthState();
  }

  Future<void> _showSettingsDialog() async {
    await showDialog<bool>(
      context: context,
      builder: (context) => WindowsSettingsDialog(
        closeToTray: _closeToTray,
        autoStart: _autoStart,
        autoConnect: _autoConnect,
        autoConnectRetry: _autoConnectRetry,
        autoConnectCountryMode: _autoConnectCountryMode,
        fixedCountryCode: _fixedCountryCode,
        proxyMode: _proxyMode,
        restoreProxy: _restoreProxy,
        dnsProtect: _dnsProtect,
        countries: _controller.countries,
        onSave: (settings) async {
          // Apply settings
          setState(() {
            _closeToTray = settings['closeToTray'];
            _autoStart = settings['autoStart'];
            _autoConnect = settings['autoConnect'];
            _autoConnectRetry = settings['autoConnectRetry'];
            _autoConnectCountryMode = settings['autoConnectCountryMode'];
            _fixedCountryCode = settings['fixedCountryCode'];
            _proxyMode = settings['proxyMode'];
            _restoreProxy = settings['restoreProxy'];
            _dnsProtect = settings['dnsProtect'];
          });

          // Save to preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('win_close_to_tray', _closeToTray);
          await prefs.setBool('win_auto_connect', _autoConnect);
          await prefs.setBool('win_auto_connect_retry', _autoConnectRetry);
          await prefs.setString('win_auto_country_mode', _autoConnectCountryMode);
          if (_fixedCountryCode != null) {
            await prefs.setString('win_auto_country_code', _fixedCountryCode!);
          } else {
            await prefs.remove('win_auto_country_code');
          }
          await prefs.setString('win_proxy_mode', _proxyMode.name);
          await prefs.setBool('win_restore_proxy', _restoreProxy);
          await prefs.setBool('win_dns_protect', _dnsProtect);

          // Apply to adapter
          widget.adapter.proxyMode = _proxyMode;
          widget.adapter.restoreProxyOnDisconnect = _restoreProxy;
          widget.adapter.vpnManager.dnsProtectionEnabled = _dnsProtect;

          // Prompt for reconnection if needed
          if (widget.controller.status.value == ConnectionStatus.connected) {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('立即重新连接？'),
                content: const Text('是否现在重新连接以应用新设置？'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('稍后'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('重新连接'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await widget.controller.disconnect(userInitiated: false);
              await _connectSelected();
            }
          }
        },
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('退出登录将断开当前连接，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认退出'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Disconnect if connected
      if (widget.controller.status.value == ConnectionStatus.connected) {
        await widget.controller.disconnect(userInitiated: true);
      }

      // Logout
      await Get.find<AuthController>().removeUserToken();
      
      // Refresh UI
      if (!mounted) return;
      setState(() {
        _isLoggedIn = false;
        _userLabel = '登录';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已退出登录')),
      );
    }
  }

  Widget _buildConnectAction() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          ElevatedButton.icon(
            onPressed: _isLoggedIn
                ? () async {
                    final state = widget.controller.status.value;
                    if (state == ConnectionStatus.connected) {
                      await widget.controller.disconnect(userInitiated: true);
                    } else {
                      if (_selectedNode == null) {
                        final pick = NodeSelector.pickBest(_controller.vpnServers) ??
                            _controller.vpnServers.firstWhere(
                              (n) => n.health != NodeHealth.unavailable,
                              orElse: () => _controller.vpnServers.first,
                            );
                        setState(() {
                          _selectedNode = pick;
                        });
                      }
                      await _connectSelected();
                    }
                  }
                : _showLoginDialog,
            icon: const Icon(Icons.power_settings_new),
            label: Text(
              widget.controller.status.value == ConnectionStatus.connected
                  ? '断开'
                  : '连接',
            ),
          ),
          const SizedBox(width: 12),
          if (!_isLoggedIn)
            const Text(
              '登录后可连接节点',
              style: TextStyle(color: Colors.black54),
            ),
        ],
      ),
    );
  }

  Future<void> _refreshAuthState() async {
    final authController = Get.find<AuthController>();
    final profileController = Get.find<ProfileController>();
    final token = await authController.getAuthToken();
    final loggedIn = token.isNotEmpty;
    String label = '登录';
    if (loggedIn) {
      await profileController.getProfileData();
      final data = profileController.profileData;
      if (data is Map && data['email'] != null) {
        label = data['email'].toString();
      } else {
        label = '已登录';
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoggedIn = loggedIn;
      _userLabel = label;
    });
  }
}

class _HealthIndicator extends StatelessWidget {
  final ProxyNode node;

  const _HealthIndicator({required this.node});

  Widget _bars(int level, Color color) {
    const width = 4.0;
    const spacing = 2.0;
    final heights = [6.0, 9.0, 12.0, 15.0];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        final active = index < level;
        return Container(
          width: width,
          height: heights[index],
          margin: EdgeInsets.only(right: index == 3 ? 0 : spacing),
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (node.health) {
      case NodeHealth.testing:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case NodeHealth.unknown:
        return _bars(0, Colors.grey);
      case NodeHealth.unavailable:
        return const Icon(Icons.close, color: Colors.redAccent, size: 16);
      case NodeHealth.poor:
        return _bars(1, Colors.orange);
      case NodeHealth.fair:
        return _bars(2, Colors.yellow);
      case NodeHealth.good:
        return _bars(3, Colors.lightGreen);
      case NodeHealth.excellent:
        return _bars(4, Colors.green);
    }
  }
}

String _describeTestError(String? error) {
  switch (error) {
    case 'timeout':
      return '超时';
    case 'handshake_failed':
      return '握手失败';
    case 'config_error':
      return '配置错误';
    case 'latency_missing':
      return '无延迟';
    case 'unavailable':
      return '不可用';
    default:
      return '不可用';
  }
}
