import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../../controller/auth_controller.dart';
import '../../controller/v2ray_vpn_controller.dart';
import '../../core/onboarding/onboarding_controller.dart';
import '../../core/onboarding/onboarding_state.dart';
import '../../core/models/country_item.dart';
import '../../core/connection/connection_controller.dart';
import '../../core/models/proxy_node.dart';
import '../../core/selector/node_selector.dart';
import '../../core/speedtest/windows_real_tester.dart';
import '../../data/repository/v2ray_repo.dart';
import '../../di_container.dart' as di;
import '../../platform/windows/admin_check.dart';
import '../../platform/windows/autostart.dart';
import '../../platform/windows/connection_adapter.dart';
import '../../platform/windows/system_proxy.dart';
import '../../platform/windows/tray_service.dart';
import '../../platform/windows/privilege_helper.dart';
import '../../ui/shared/auth/signin_screen.dart';
import 'onboarding/onboarding_wizard.dart';
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
  late final AuthController _authController;
  late final V2rayVpnController _controller;
  OnboardingController? _onboardingController;
  late final WindowsTrayService _trayService;
  CountryItem? _selectedCountry;
  ProxyNode? _selectedNode;
  bool _isTesting = false;
  bool _showOnboarding = false;
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

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
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
    _loadSettings();

    Future<void>.microtask(_initOnboarding);

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
    _onboardingController?.removeListener(_handleOnboardingStateChange);
    widget.controller.status.removeListener(_syncTrayState);
    widget.controller.status.removeListener(_handleStatusChange);
    windowManager.removeListener(this);
    _trayService.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    if (_closeToTray) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimized to tray.')),
      );
      await windowManager.hide();
    } else {
      await _exitApp();
    }
  }

  Future<void> _exitApp() async {
    await widget.controller.disconnect(userInitiated: true);
    await windowManager.destroy();
  }

  Future<void> _toggleConnection() async {
    if (widget.controller.status.value == ConnectionStatus.connected ||
        widget.controller.status.value == ConnectionStatus.starting ||
        widget.controller.status.value == ConnectionStatus.reconnecting) {
      await widget.controller.disconnect(userInitiated: true);
      return;
    }
    if (_selectedNode == null) {
      return;
    }
    await _connectSelected();
  }

  Future<void> _initOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    _onboardingController = OnboardingController(
      repo: di.sl<V2rayVpnRepo>(),
      prefs: prefs,
      connector: _connectFromOnboarding,
    )..addListener(_handleOnboardingStateChange);
    await _maybeStartOnboarding();
  }

  Future<void> _maybeStartOnboarding({bool force = false}) async {
    final onboarding = _onboardingController;
    if (onboarding == null) {
      return;
    }
    final token = await _authController.getAuthToken();
    if (token.isEmpty) {
      return;
    }
    if (force) {
      onboarding.reset();
    }
    final started = await onboarding.startIfNeeded();
    if (started && mounted) {
      setState(() {
        _showOnboarding = true;
      });
    }
  }

  Future<bool> _connectFromOnboarding(ProxyNode node) async {
    if (!mounted) {
      return false;
    }
    setState(() {
      _selectedNode = node;
    });
    await _syncTrayState();
    try {
      await widget.controller.connect(node, silent: _silentLaunch);
      return widget.controller.status.value == ConnectionStatus.connected;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connect failed: $e')),
        );
      }
      return false;
    }
  }

  void _handleOnboardingStateChange() {
    final onboarding = _onboardingController;
    if (onboarding == null || !mounted) {
      return;
    }
    final step = onboarding.state.step;
    if (step == OnboardingStep.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最佳节点已连接')),
      );
      setState(() {
        _showOnboarding = false;
      });
    }
    if (step == OnboardingStep.skipped) {
      setState(() {
        _showOnboarding = false;
      });
    }
    if (step == OnboardingStep.failed) {
      setState(() {
        _showOnboarding = true;
      });
    }
  }

  Future<void> _connectSelected() async {
    final node = _selectedNode;
    if (node == null) {
      return;
    }
    if (_dnsProtect && !WindowsAdminCheck.isAdmin()) {
      if (!_silentLaunch) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DNS protection requires administrator permissions.')),
        );
      }
      widget.adapter.vpnManager.dnsProtectionEnabled = false;
    } else {
      widget.adapter.vpnManager.dnsProtectionEnabled = _dnsProtect;
    }
    try {
      await widget.controller.connect(node, silent: _silentLaunch);
    } catch (e) {
      if (!mounted) {
        return;
      }
      if (!_silentLaunch) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connect failed: $e')),
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
    await _trayService.update(
      nodes: _controller.vpnServers,
      current: _selectedNode,
      isConnected: widget.controller.status.value == ConnectionStatus.connected,
    );
  }

  Future<void> _handleNotification(String message) async {
    await _trayService.showMessage(message);
    if (!_silentLaunch && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _handleStatusChange() async {
    if (widget.controller.status.value == ConnectionStatus.connected) {
      await _persistLastConnected();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('TSVPN for Windows'),
        actions: [
          IconButton(
            tooltip: 'Login',
            onPressed: () async {
              await Get.to(() => const SignInScreen());
              _controller.getCountries();
              await _maybeStartOnboarding();
            },
            icon: const Icon(Icons.login),
          ),
          IconButton(
            tooltip: 'Onboarding',
            onPressed: () {
              setState(() {
                _showOnboarding = true;
              });
              _maybeStartOnboarding(force: true);
            },
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: 'Retest nodes',
            onPressed: _isTesting ? null : () => _runSpeedTest(force: true),
            icon: const Icon(Icons.speed),
          ),
          ValueListenableBuilder<ConnectionStatus>(
            valueListenable: widget.controller.status,
            builder: (context, state, _) {
              final label = state == ConnectionStatus.connected
                  ? 'Disconnect'
                  : state == ConnectionStatus.starting
                      ? 'Connecting...'
                      : state == ConnectionStatus.reconnecting
                          ? 'Reconnecting...'
                          : 'Connect';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ElevatedButton(
                  onPressed: state == ConnectionStatus.starting ||
                          state == ConnectionStatus.reconnecting
                      ? null
                      : () async {
                          if (state == ConnectionStatus.connected) {
                            await widget.controller.disconnect(userInitiated: true);
                          } else {
                            await _connectSelected();
                          }
                        },
                  child: Text(label),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Row(
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
          if (_showOnboarding && _onboardingController != null)
            Positioned(
              right: 24,
              top: 24,
              child: OnboardingWizard(
                controller: _onboardingController!,
                onClose: () {
                  setState(() {
                    _showOnboarding = false;
                  });
                },
              ),
            ),
        ],
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
          return const Center(child: Text('Select a country to load nodes.'));
        }
        if (controller.isLoadingNodes) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.nodesError != null) {
          return Center(child: Text(controller.nodesError!));
        }

        final nodes = controller.vpnServers;
        if (nodes.isEmpty) {
          return const Center(child: Text('No nodes found.'));
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
                    Text('Testing nodes...'),
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
                  final enabled = node.available;
                  return ListTile(
                    selected: selected,
                    enabled: enabled,
                    title: Text(node.displayName),
                    subtitle: Text(node.type.toUpperCase()),
                    trailing: _LatencyBadge(node: node, isBest: best),
                    onTap: enabled ? () => _selectNode(node) : null,
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
            title: const Text('Close to tray'),
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
            title: const Text('Start with Windows'),
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
                  SnackBar(content: Text('Auto start failed: $e')),
                );
              }
            },
          ),
          SwitchListTile(
            title: const Text('Auto connect on startup'),
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
                    SnackBar(content: Text('Update auto start failed: $e')),
                  );
                }
              }
            },
          ),
          if (_autoConnect)
            ListTile(
              title: const Text('Auto connect country'),
              trailing: DropdownButton<String>(
                value: _autoConnectCountryMode,
                items: const [
                  DropdownMenuItem(value: 'last', child: Text('Last used')),
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
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
                hint: const Text('Select country'),
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
              title: const Text('Keep retrying on failure'),
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
            title: const Text('System proxy mode'),
            trailing: DropdownButton<ProxyMode>(
              value: _proxyMode,
              items: const [
                DropdownMenuItem(value: ProxyMode.off, child: Text('Off')),
                DropdownMenuItem(value: ProxyMode.global, child: Text('Global')),
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
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Restore proxy on disconnect'),
            value: _restoreProxy,
            onChanged: (value) async {
              if (!value) {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Disable proxy restore?'),
                    content: const Text(
                      'Disabling this may leave system proxy enabled after disconnect.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Disable'),
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
            },
          ),
          SwitchListTile(
            title: const Text('DNS protection'),
            subtitle: const Text('Disable may leak DNS queries'),
            value: _dnsProtect,
            onChanged: (value) async {
              setState(() {
                _dnsProtect = value;
              });
              widget.adapter.vpnManager.dnsProtectionEnabled = value;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('win_dns_protect', value);
            },
          ),
          ListTile(
            title: const Text('Run onboarding'),
            subtitle: const Text('Re-run first time setup'),
            trailing: const Icon(Icons.auto_awesome),
            onTap: () async {
              setState(() {
                _showOnboarding = true;
              });
              await _maybeStartOnboarding(force: true);
            },
          ),
        ],
      ),
    );
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
        'Unavailable',
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
