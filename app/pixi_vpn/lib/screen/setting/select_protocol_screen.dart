import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixi_vpn/screen/home/wg_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../controller/general_setting_controller.dart';
import '../home/open_vpn_home_screen.dart';
import '../home/v2_home_screen.dart';

class SelectProtocolScreen extends StatefulWidget {
  const SelectProtocolScreen({super.key});

  @override
  State<SelectProtocolScreen> createState() => _SelectProtocolScreenState();
}

class _SelectProtocolScreenState extends State<SelectProtocolScreen> {
  String? selectedProtocol;

  @override
  void initState() {
    super.initState();
    _loadSelectedProtocol();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<GeneralSettingController>().getGeneralData();
    });
  }

  Future<void> _loadSelectedProtocol() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedProtocol = prefs.getString('selected_vpn_protocol');
    });
  }

  Future<void> _saveAndNavigate(String protocol, Widget screen) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_vpn_protocol', protocol);

    Get.offAll(() => screen, transition: Transition.fade);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.white,
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "选择协议",
                      style: GoogleFonts.aBeeZee(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Protocol List
              Expanded(
                child: GetBuilder<GeneralSettingController>(
                  builder: (controller) {
                    if (controller.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7BC67E),
                          strokeWidth: 2,
                        ),
                      );
                    }

                    final generalData = controller.appGeneralData;

                    if (generalData == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 60, color: Colors.black54),
                            const SizedBox(height: 16),
                            Text(
                              "无法加载协议",
                              style: GoogleFonts.aBeeZee(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Build protocol list based on status
                    List<Map<String, dynamic>> availableProtocols = [];

                    if (generalData['openvpn_status'] == '1' && !GetPlatform.isMacOS) {
                      availableProtocols.add({
                        'name': 'OpenVPN',
                        'key': 'openvpn',
                        'icon': Icons.vpn_key_rounded,
                        'description': '可靠且安全的 VPN 协议',
                        'screen': const OpenVpnHomeScreen(),
                      });
                    }

                    if (generalData['v2ray_status'] == '1') {
                      availableProtocols.add({
                        'name': 'V2Ray',
                        'key': 'v2ray',
                        'icon': Icons.shield_outlined,
                        'description': '带有混淆的高级协议',
                        'screen': const V2HomeScreen(),
                      });
                    }

                    if (generalData['wireguard_status'] == '1') {
                      availableProtocols.add({
                        'name': 'WireGuard',
                        'key': 'wireguard',
                        'icon': Icons.flash_on_rounded,
                        'description': '快速且现代的 VPN 协议',
                        'screen': const WGHomeScreen(),
                      });
                    }


                    if (availableProtocols.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.block, size: 60, color: Colors.black54),
                            const SizedBox(height: 16),
                            Text(
                              "无可用协议",
                              style: GoogleFonts.aBeeZee(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: availableProtocols.length,
                      itemBuilder: (context, index) {
                        final protocol = availableProtocols[index];
                        final isSelected = selectedProtocol == protocol['key'];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildProtocolCard(
                            name: protocol['name'],
                            key: protocol['key'],
                            icon: protocol['icon'],
                            description: protocol['description'],
                            isSelected: isSelected,
                            onTap: () => _saveAndNavigate(
                              protocol['key'],
                              protocol['screen'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProtocolCard({
    required String name,
    required String key,
    required IconData icon,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7BC67E).withValues(alpha: 0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7BC67E)
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF7BC67E)
                    : const Color(0xFF7BC67E).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF7BC67E),
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            // Protocol Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.aBeeZee(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.aBeeZee(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Selection Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF7BC67E)
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF7BC67E)
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: Icon(
                isSelected ? Icons.check : Icons.circle,
                color: isSelected ? Colors.white : Colors.transparent,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
