// Help Center Screen
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixi_vpn/controller/help_center_controller.dart';
import 'package:pixi_vpn/utils/app_colors.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {

  @override
  void initState() {
    // Load help content
    Get.find<HelpCenterController>().getHelpCenterData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<HelpCenterController>(
      builder: (helpCenterController) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title:  Text(
              '帮助中心',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
            child: Column(
              children: [
                // optional header / intro
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '查找常见问题解答和故障排除步骤。',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),

                Expanded(
                  child: helpCenterController.isLoading == false && helpCenterController.helpCenterData != null
                      ? RefreshIndicator(
                          onRefresh: () async {
                            await helpCenterController.getHelpCenterData();
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 12, bottom: 24),
                            itemCount: helpCenterController.helpCenterData.length,
                            itemBuilder: (context, index) {
                              final article = helpCenterController.helpCenterData[index];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article['question'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      article['answer'] ?? '',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.appPrimaryColor,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
