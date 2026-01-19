import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixi_vpn/controller/v2ray_vpn_controller.dart';
import 'package:pixi_vpn/model/country_item.dart';
import 'package:pixi_vpn/model/proxy_node.dart';
import 'package:pixi_vpn/ui/shared/home/v2_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pixi_vpn/utils/app_colors.dart';
import 'package:pixi_vpn/v2ray/node_tester.dart';

class V2NodesScreen extends StatefulWidget {
  final CountryItem country;

  const V2NodesScreen({super.key, required this.country});

  @override
  State<V2NodesScreen> createState() => _V2NodesScreenState();
}

class _V2NodesScreenState extends State<V2NodesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = Get.find<V2rayVpnController>();
      await controller.loadCountryNodes(widget.country.code);
      await _runSpeedTest();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveSelectedNode(ProxyNode node) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodeBase64(String input) => base64Encode(utf8.encode(input));

    prefs.setInt('id', 0);
    prefs.setString('name_v', encodeBase64(node.displayName));
    prefs.setString('link_v', encodeBase64(node.raw));
  }

  Future<void> _runSpeedTest({bool force = false}) async {
    final controller = Get.find<V2rayVpnController>();
    if (controller.vpnServers.isEmpty) {
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      if (force) {
        await NodeTester.clearCacheFor(controller.vpnServers);
      }

      final sorted = await NodeTester.testAndSort(controller.vpnServers);
      controller.setVpnServers(sorted);
    } catch (_) {
      // Avoid crashing UI if a test fails unexpectedly.
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<V2rayVpnController>(
      builder: (controller) {
        final isLoading = controller.isLoadingNodes;
        final nodes = controller.vpnServers;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
            ),
            title: Text(
              "${widget.country.name} 节点",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            actions: [
              IconButton(
                tooltip: '重新测速',
                onPressed: _isTesting ? null : () => _runSpeedTest(force: true),
                icon: const Icon(Icons.refresh, color: Colors.black),
              ),
            ],
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.white, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  if (_isTesting)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '测速中...',
                            style: GoogleFonts.poppins(color: Colors.black54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      style: GoogleFonts.poppins(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: '搜索节点...',
                        hintStyle: GoogleFonts.roboto(
                          fontSize: 16,
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                        prefixIcon: const Icon(Icons.search, color: Colors.black),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.black),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.black.withValues(alpha: 0.03),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: AppColors.appPrimaryColor,
                              strokeWidth: 2,
                            ),
                          )
                        : _buildNodesList(controller.nodesError, nodes),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNodesList(String? error, List<ProxyNode> nodes) {
    if (error != null) {
      return Center(
        child: Text(
          error,
          style: GoogleFonts.poppins(color: Colors.black54),
        ),
      );
    }

    final filtered = _searchQuery.isEmpty
        ? nodes
        : nodes.where((node) {
            final haystack = [
              node.displayName,
              node.host ?? '',
              node.type,
            ].join(' ').toLowerCase();
            return haystack.contains(_searchQuery);
          }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? "未找到节点" : "未找到匹配的节点",
          style: GoogleFonts.poppins(color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: GestureDetector(
            onTap: () async {
              await _saveSelectedNode(item);
              Get.snackbar("提示", '节点已保存', backgroundColor: Colors.green, colorText: Colors.white);
              Get.offAll(() => const V2HomeScreen(), transition: Transition.leftToRight);
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.06),
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.06),
                  child: Text(
                    item.type.toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                  ),
                ),
                title: Text(
                  item.displayName,
                  style: GoogleFonts.poppins(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  item.host ?? '',
                  style: GoogleFonts.poppins(
                    color: Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLatencyIndicator(item),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLatencyIndicator(ProxyNode node) {
    if (_isTesting && node.testedAt == null) {
      return Text(
        '测速中...',
        style: GoogleFonts.poppins(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (node.testedAt == null) {
      return Text(
        '未测速',
        style: GoogleFonts.poppins(
          color: Colors.grey,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    if (!node.available) {
      return Text(
        '超时/不可用',
        style: GoogleFonts.poppins(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final latency = node.latencyMs;
    if (latency == null || latency > 3000) {
      return Text(
        '超时/不可用',
        style: GoogleFonts.poppins(
          color: Colors.red,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    if (latency <= 20) {
      return Text(
        '≤20ms',
        style: GoogleFonts.poppins(
          color: Colors.green,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    Color latencyColor;
    if (latency < 150) {
      latencyColor = Colors.green;
    } else if (latency < 300) {
      latencyColor = Colors.orange;
    } else {
      latencyColor = Colors.red;
    }

    return Text(
      '${latency}ms',
      style: GoogleFonts.poppins(
        color: latencyColor,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
