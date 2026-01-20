import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../../controller/v2ray_vpn_controller.dart';
import '../../core/models/country_item.dart';
import '../../core/connection/connection_controller.dart';
import '../../core/models/proxy_node.dart';
import '../../core/selector/node_selector.dart';
import '../../core/speedtest/windows_real_tester.dart';
import '../../platform/windows/admin_check.dart';
import '../../platform/windows/autostart.dart';
import '../../platform/windows/connection_adapter.dart';
import '../../platform/windows/system_proxy.dart';
import '../../platform/windows/tray_service.dart';
import '../../platform/windows/privilege_helper.dart';
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
  bool _settingsDirty = false;
  bool _lastConnectFailed = false;
  int _reconnectFailureCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<V2rayVpnController>();
    _controller.getCountries();
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
    if (!node.available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('该节点当前不可用，请稍后重试。')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('连接失败，请稍后重试。')),
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
        timeout: const Duration(milliseconds: 1200),
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
          IconButton(
            tooltip: '重新测速',
            onPressed: _isTesting ? null : () => _runSpeedTest(force: true),
            icon: const Icon(Icons.speed),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: widget.controller.networkAvailable,
            builder: (context, isNetworkAvailable, _) {
              return ValueListenableBuilder<ConnectionStatus>(
                valueListenable: widget.controller.status,
                builder: (context, state, _) {
                  final connectedLabel = _selectedNode?.displayName == null
                      ? '已连接'
                      : '已连接 · ${_selectedNode?.displayName}';
                  final label = state == ConnectionStatus.connected
                      ? connectedLabel
                      : state == ConnectionStatus.starting
                          ? '正在连接…'
                          : state == ConnectionStatus.reconnecting
                              ? (isNetworkAvailable
                                  ? '网络波动，正在重连…'
                                  : '网络中断，等待恢复…')
                              : _lastConnectFailed
                                  ? '连接失败'
                                  : '未连接';
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: ElevatedButton(
                      onPressed: state == ConnectionStatus.starting ||
                              state == ConnectionStatus.reconnecting
                          ? null
                          : () async {
                              if (state == ConnectionStatus.connected) {
                                await widget.controller.disconnect(
                                  userInitiated: true,
                                );
                              } else {
                                await _connectSelected();
                              }
                            },
                      child: Text(label),
                    ),
                  );
                },
              );
            },
          ),
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
            _buildSettingsCard(),
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
                  final selected = _selectedNode?.id == node.id;
                  final best = bestNode?.id == node.id;
                  final available = node.available;
                  final titleStyle =
                      available ? null : const TextStyle(color: Colors.grey);
                  final subtitle = available
                      ? Text(node.type.toUpperCase())
                      : Tooltip(
                          message: '该节点当前无法连接，请稍后重试',
                          child: const Text(
                            '不可用',
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        );
                  return ListTile(
                    selected: selected,
                    title: Text(node.displayName, style: titleStyle),
                    subtitle: subtitle,
                    trailing: _LatencyBadge(node: node, isBest: best),
                    onTap: available
                        ? () => _selectNode(node)
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('该节点当前不可用，请稍后重试。'),
                              ),
                            );
                          },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('关闭后最小化到托盘'),
            value: _closeToTray,
            onChanged: (value) async {
              setState(() {
                _closeToTray = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('win_close_to_tray', value);
            },
          ),
          SwitchListTile(
            title: const Text('开机启动'),
            value: _autoStart,
            onChanged: (value) async {
              try {
                if (value) {
                  await WindowsAutoStart.enableAutoStart(autoConnect: _autoConnect);
                } else {
                  await WindowsAutoStart.disableAutoStart();
                }
                setState(() {
                  _autoStart = value;
                });
              } catch (e) {
                if (!mounted) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('开机启动设置失败：$e')),
                );
              }
            },
          ),
          SwitchListTile(
            title: const Text('开机后自动连接'),
            value: _autoConnect,
            onChanged: (value) async {
              setState(() {
                _autoConnect = value;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('win_auto_connect', value);
              if (_autoStart) {
                try {
                  await WindowsAutoStart.enableAutoStart(autoConnect: value);
                } catch (e) {
                  if (!mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('更新开机启动失败：$e')),
                  );
                }
              }
            },
          ),
          if (_autoConnect)
            ListTile(
              title: const Text('自动连接国家'),
              trailing: DropdownButton<String>(
                value: _autoConnectCountryMode,
                items: const [
                  DropdownMenuItem(value: 'last', child: Text('上次使用')),
                  DropdownMenuItem(value: 'fixed', child: Text('固定国家')),
                ],
                onChanged: (value) async {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _autoConnectCountryMode = value;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('win_auto_country_mode', value);
                },
              ),
            ),
          if (_autoConnect && _autoConnectCountryMode == 'fixed')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _fixedCountryCode,
                hint: const Text('选择国家'),
                items: _controller.countries
                    .map(
                      (country) => DropdownMenuItem(
                        value: country.code,
                        child: Text(country.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) async {
                  setState(() {
                    _fixedCountryCode = value;
                  });
                  final prefs = await SharedPreferences.getInstance();
                  if (value == null) {
                    await prefs.remove('win_auto_country_code');
                  } else {
                    await prefs.setString('win_auto_country_code', value);
                  }
                },
              ),
            ),
          if (_autoConnect)
            SwitchListTile(
              title: const Text('失败后持续重试'),
              value: _autoConnectRetry,
              onChanged: (value) async {
                setState(() {
                  _autoConnectRetry = value;
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('win_auto_connect_retry', value);
              },
            ),
          ListTile(
            title: const Text('系统代理模式'),
            trailing: DropdownButton<ProxyMode>(
              value: _proxyMode,
              items: const [
                DropdownMenuItem(value: ProxyMode.off, child: Text('关闭')),
                DropdownMenuItem(value: ProxyMode.global, child: Text('全局')),
                DropdownMenuItem(value: ProxyMode.pac, child: Text('PAC')),
              ],
              onChanged: (value) async {
                if (value == null) {
                  return;
                }
                setState(() {
                  _proxyMode = value;
                });
                widget.adapter.proxyMode = value;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('win_proxy_mode', value.name);
                _markSettingsDirty();
                await _promptReconnectIfNeeded();
              },
            ),
          ),
          SwitchListTile(
            title: const Text('断开后恢复系统代理'),
            value: _restoreProxy,
            onChanged: (value) async {
              if (!value) {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('关闭恢复系统代理？'),
                    content: const Text('关闭后可能导致系统代理无法自动恢复。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('确认'),
                      ),
                    ],
                  ),
                );
                if (confirmed != true) {
                  return;
                }
              }
              setState(() {
                _restoreProxy = value;
              });
              widget.adapter.restoreProxyOnDisconnect = value;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('win_restore_proxy', value);
              _markSettingsDirty();
              await _promptReconnectIfNeeded();
            },
          ),
          SwitchListTile(
            title: const Text('DNS 防泄漏'),
            subtitle: const Text('关闭可能导致 DNS 泄漏'),
            value: _dnsProtect,
            onChanged: (value) async {
              setState(() {
                _dnsProtect = value;
              });
              widget.adapter.vpnManager.dnsProtectionEnabled = value;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('win_dns_protect', value);
              _markSettingsDirty();
              await _promptReconnectIfNeeded();
            },
          ),
          if (_settingsDirty)
            const Padding(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '部分设置将在重新连接后生效',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ),
          ExpansionTile(
            title: const Text('Sing-box 配置'),
            subtitle: Text(
              widget.adapter.activeConfig?.name ?? '未选择',
            ),
            children: [
              if (widget.adapter.availableConfigs.isEmpty)
                const ListTile(
                  title: Text('暂无配置'),
                  subtitle: Text('连接一次后会自动拉取配置'),
                )
              else
                ...widget.adapter.availableConfigs.map(
                  (config) => ListTile(
                    title: Text(config.name),
                    subtitle: Text(config.type),
                    trailing: widget.adapter.activeConfig?.id == config.id
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _markSettingsDirty() {
    if (_settingsDirty) {
      return;
    }
    setState(() {
      _settingsDirty = true;
    });
  }

  Future<void> _promptReconnectIfNeeded() async {
    if (widget.controller.status.value != ConnectionStatus.connected) {
      return;
    }
    if (!mounted) {
      return;
    }
    final confirm = await showDialog<bool>(
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
    if (confirm == true) {
      await widget.controller.disconnect(userInitiated: false);
      await _connectSelected();
      setState(() {
        _settingsDirty = false;
      });
    }
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
}

class _LatencyBadge extends StatelessWidget {
  final ProxyNode node;
  final bool isBest;

  const _LatencyBadge({required this.node, required this.isBest});

  @override
  Widget build(BuildContext context) {
    if (!node.available || node.latencyMs == null) {
      return const Text(
        '不可用',
        style: TextStyle(color: Colors.redAccent),
      );
    }

    final displayMs = node.tlsMs ?? node.tcpMs ?? node.latencyMs!;
    final isTls = node.tlsMs != null;
    final labelPrefix = isTls ? 'TLS' : 'TCP';
    final latency = displayMs < 10 ? 10 : displayMs;
    Color color;
    if (latency < 150) {
      color = Colors.green;
    } else if (latency < 300) {
      color = Colors.orange;
    } else {
      color = Colors.redAccent;
    }

    final valueLabel = displayMs < 10 ? '≤10ms' : '$latency ms';
    final label = isBest ? '$labelPrefix $valueLabel (Best)' : '$labelPrefix $valueLabel';
    return Text(label, style: TextStyle(color: color));
  }
}
