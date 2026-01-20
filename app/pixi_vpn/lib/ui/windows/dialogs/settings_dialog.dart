import 'package:flutter/material.dart';

import '../../../platform/windows/autostart.dart';
import '../../../platform/windows/system_proxy.dart';

class WindowsSettingsDialog extends StatefulWidget {
  final bool closeToTray;
  final bool autoStart;
  final bool autoConnect;
  final bool autoConnectRetry;
  final String autoConnectCountryMode;
  final String? fixedCountryCode;
  final ProxyMode proxyMode;
  final bool restoreProxy;
  final bool dnsProtect;
  final List<dynamic> countries;
  final Function(Map<String, dynamic>) onSave;

  const WindowsSettingsDialog({
    super.key,
    required this.closeToTray,
    required this.autoStart,
    required this.autoConnect,
    required this.autoConnectRetry,
    required this.autoConnectCountryMode,
    this.fixedCountryCode,
    required this.proxyMode,
    required this.restoreProxy,
    required this.dnsProtect,
    required this.countries,
    required this.onSave,
  });

  @override
  State<WindowsSettingsDialog> createState() => _WindowsSettingsDialogState();
}

class _WindowsSettingsDialogState extends State<WindowsSettingsDialog> {
  late bool _closeToTray;
  late bool _autoStart;
  late bool _autoConnect;
  late bool _autoConnectRetry;
  late String _autoConnectCountryMode;
  String? _fixedCountryCode;
  late ProxyMode _proxyMode;
  late bool _restoreProxy;
  late bool _dnsProtect;
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _closeToTray = widget.closeToTray;
    _autoStart = widget.autoStart;
    _autoConnect = widget.autoConnect;
    _autoConnectRetry = widget.autoConnectRetry;
    _autoConnectCountryMode = widget.autoConnectCountryMode;
    _fixedCountryCode = widget.fixedCountryCode;
    _proxyMode = widget.proxyMode;
    _restoreProxy = widget.restoreProxy;
    _dnsProtect = widget.dnsProtect;
  }

  void _markDirty() {
    setState(() {
      _hasUnsavedChanges = true;
    });
  }

  Future<void> _saveSettings() async {
    widget.onSave({
      'closeToTray': _closeToTray,
      'autoStart': _autoStart,
      'autoConnect': _autoConnect,
      'autoConnectRetry': _autoConnectRetry,
      'autoConnectCountryMode': _autoConnectCountryMode,
      'fixedCountryCode': _fixedCountryCode,
      'proxyMode': _proxyMode,
      'restoreProxy': _restoreProxy,
      'dnsProtect': _dnsProtect,
    });
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.settings, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    '设置',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close),
                    tooltip: '关闭',
                  ),
                ],
              ),
            ),

            // Settings Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      '常规设置',
                      [
                        SwitchListTile(
                          title: const Text('关闭后最小化到托盘'),
                          value: _closeToTray,
                          onChanged: (value) {
                            setState(() {
                              _closeToTray = value;
                            });
                            _markDirty();
                          },
                        ),
                        SwitchListTile(
                          title: const Text('开机启动'),
                          value: _autoStart,
                          onChanged: (value) async {
                            try {
                              if (value) {
                                await WindowsAutoStart.enableAutoStart(
                                  autoConnect: _autoConnect,
                                );
                              } else {
                                await WindowsAutoStart.disableAutoStart();
                              }
                              setState(() {
                                _autoStart = value;
                              });
                              _markDirty();
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('开机启动设置失败：$e')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      '自动连接',
                      [
                        SwitchListTile(
                          title: const Text('开机后自动连接'),
                          value: _autoConnect,
                          onChanged: (value) {
                            setState(() {
                              _autoConnect = value;
                            });
                            _markDirty();
                          },
                        ),
                        if (_autoConnect) ...[
                          ListTile(
                            title: const Text('自动连接国家'),
                            trailing: DropdownButton<String>(
                              value: _autoConnectCountryMode,
                              items: const [
                                DropdownMenuItem(
                                  value: 'last',
                                  child: Text('上次使用'),
                                ),
                                DropdownMenuItem(
                                  value: 'fixed',
                                  child: Text('固定国家'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _autoConnectCountryMode = value;
                                  });
                                  _markDirty();
                                }
                              },
                            ),
                          ),
                          if (_autoConnectCountryMode == 'fixed')
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _fixedCountryCode,
                                hint: const Text('选择国家'),
                                items: widget.countries
                                    .map<DropdownMenuItem<String>>(
                                      (country) => DropdownMenuItem<String>(
                                        value: country.code,
                                        child: Text(country.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _fixedCountryCode = value;
                                  });
                                  _markDirty();
                                },
                              ),
                            ),
                          SwitchListTile(
                            title: const Text('失败后持续重试'),
                            value: _autoConnectRetry,
                            onChanged: (value) {
                              setState(() {
                                _autoConnectRetry = value;
                              });
                              _markDirty();
                            },
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      '代理设置',
                      [
                        ListTile(
                          title: const Text('系统代理模式'),
                          trailing: DropdownButton<ProxyMode>(
                            value: _proxyMode,
                            items: const [
                              DropdownMenuItem(
                                value: ProxyMode.off,
                                child: Text('关闭'),
                              ),
                              DropdownMenuItem(
                                value: ProxyMode.global,
                                child: Text('全局'),
                              ),
                              DropdownMenuItem(
                                value: ProxyMode.pac,
                                child: Text('PAC'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _proxyMode = value;
                                });
                                _markDirty();
                              }
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
                            _markDirty();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      '高级设置',
                      [
                        SwitchListTile(
                          title: const Text('DNS 防泄漏'),
                          subtitle: const Text('关闭可能导致 DNS 泄漏'),
                          value: _dnsProtect,
                          onChanged: (value) {
                            setState(() {
                              _dnsProtect = value;
                            });
                            _markDirty();
                          },
                        ),
                      ],
                    ),
                    if (_hasUnsavedChanges)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text(
                          '部分设置将在重新连接后生效',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Footer Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('保存并关闭'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
