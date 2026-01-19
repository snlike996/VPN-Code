import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pixi_vpn/ui/shared/auth/signin_screen.dart';
import 'package:pixi_vpn/ui/shared/auth/sign_up_screen.dart';
import 'package:pixi_vpn/ui/shared/home/v2_home_screen.dart';
import 'package:pixi_vpn/utils/app_colors.dart';
import '../../controller/auth_controller.dart';
import '../../controller/profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _redeemCodeController = TextEditingController();

  void checkAuthAndFetchProfile() async {
    String token = await Get.find<AuthController>().getAuthToken();
    if (token.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final profileController = Get.find<ProfileController>();
        profileController.getRedeemStatus();
        profileController.getProfileData().then((value) {
          if (value == 200) {
            final profile = profileController.profileData;
            final isPremium = profile["isPremium"].toString() == "1";
            final expiredDate = DateTime.tryParse(profile["expired_date"].toString());
            final now = DateTime.now();

            if (isPremium && expiredDate != null && expiredDate.isAfter(now)) {
              log("Premium valid until: $expiredDate");
            } else {
              if (isPremium) {
                Get.find<ProfileController>().cancelSubscriptionData();
              }
              log("Premium expired or not active");
            }
            log("log data>>>$profile");
          }
        });
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAuthAndFetchProfile();
    });
  }

  @override
  void dispose() {
    _redeemCodeController.dispose();
    super.dispose();
  }

  String formatDate(String dateString) {
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM, yyyy').format(date);
    } catch (e) {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Get.back(),
            ),
            title: Text(
              '个人中心',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: FutureBuilder<String?>(
              future: Get.find<AuthController>().getAuthToken(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blue,
                  strokeWidth: 2,
                  ));
                }

                final authToken = snapshot.data;

                // Not logged in
                if (authToken == null || authToken.isEmpty) {
                  return _buildNotLoggedInUI();
                }

                if (profileController.isLoading || profileController.profileData == null) {
                  return const Center(child: CircularProgressIndicator(color: Colors.blue,
                  strokeWidth: 2,
                  ));
                }

                final data = profileController.profileData!;
                final isPremium = (data["isPremium"] ?? 0) == 1;
                final remainingDays = _remainingDays(data["expired_date"]);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    children: [
                      _buildProfileCard(data),
                      const SizedBox(height: 20),
                      _buildAccountCard(data, isPremium),
                      const SizedBox(height: 20),
                      _buildRedeemCard(
                        profileController.hasPendingRedeem,
                        isPremium,
                        remainingDays,
                      ),
                      const SizedBox(height: 30),
                      _buildLogoutButton(context),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // -------------------------------
  // COMPONENTS
  // -------------------------------

  Widget _buildProfileCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.blue.withValues(alpha: 0.12),
            child: Icon(Icons.person_rounded, color: Colors.blue, size: 45),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data["name"] ?? "未知",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data["email"] ?? "无邮箱",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> data, bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPremium ? Icons.workspace_premium_rounded : Icons.account_circle_outlined,
                color: isPremium ? Colors.blue[700] : AppColors.appPrimaryColor,
                size: 26,
              ),
              const SizedBox(width: 10),
              Text(
                isPremium ? "高级账户" : "免费账户",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isPremium ? Colors.blue[800] : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today_outlined, "加入时间", formatDate(data["created_at"] ?? "")),
          if (isPremium) ...[
            const SizedBox(height: 14),
            _buildInfoRow(Icons.timer_outlined, "有效期", "${data["validity"] ?? "-"} 天"),
          ],
        ],
      ),
    );
  }

  Widget _buildRedeemCard(bool hasPendingRedeem, bool isPremium, int? remainingDays) {
    String subtitleText;
    if (hasPendingRedeem) {
      subtitleText = "等待验证";
    } else if (isPremium && remainingDays != null && remainingDays > 0) {
      subtitleText = "高级会员，剩余${remainingDays}天";
    } else {
      subtitleText = "填写支付宝口令红包，获取365天高级会员";
    }
    return Container(
      decoration: _cardDecoration(),
      child: ListTile(
        leading: const Icon(Icons.card_giftcard_rounded, color: Colors.black),
        title: Text(
          "26.8 一年不限流量 不限速套餐",
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        subtitle: Text(
          subtitleText,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
        ),
        trailing: hasPendingRedeem
            ? Text(
                "等待验证",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
              )
            : isPremium && remainingDays != null && remainingDays > 0
                ? Text(
                    "已开通",
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                  )
                : const Icon(Icons.chevron_right_rounded, color: Colors.black54),
        onTap: hasPendingRedeem ? null : _showRedeemDialog,
      ),
    );
  }

  int? _remainingDays(dynamic expiredDateValue) {
    final expiredDate = expiredDateValue == null
        ? null
        : DateTime.tryParse(expiredDateValue.toString());
    if (expiredDate == null) {
      return null;
    }
    final now = DateTime.now();
    if (!expiredDate.isAfter(now)) {
      return 0;
    }
    return expiredDate.difference(now).inDays;
  }

  void _showRedeemDialog() {
    _redeemCodeController.clear();
    showDialog(
      context: context,
      builder: (_) => GetBuilder<ProfileController>(
        builder: (profileController) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '口令红包',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '请输入口令，提交后等待后台审核通过。',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _redeemCodeController,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: "填写口令红包",
                      hintStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.black38),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: profileController.isRedeemSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            '取消',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: profileController.isRedeemSubmitting
                              ? null
                              : () async {
                                  final code = _redeemCodeController.text.trim();
                                  if (code.isEmpty) {
                                    Fluttertoast.showToast(
                                      msg: "请输入口令",
                                      backgroundColor: Colors.orange,
                                      textColor: Colors.white,
                                    );
                                    return;
                                  }
                                  final result = await profileController.submitRedeemCode(code);
                                  final data = profileController.redeemData;
                                  final message = data is Map
                                      ? (data['message'] ?? data['error'] ?? '提交完成')
                                      : '提交完成';
                                  Fluttertoast.showToast(
                                    msg: message.toString(),
                                    backgroundColor: data is Map && data['error'] != null
                                        ? Colors.red
                                        : Colors.green,
                                    textColor: Colors.white,
                                  );
                                  if (result == 200 && (data is Map && data['error'] == null)) {
                                    Navigator.pop(context);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: profileController.isRedeemSubmitting
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  '提交',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text(
          "退出登录",
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        onPressed: () => _showLogoutDialog(context),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.appPrimaryColor, size: 20),
        const SizedBox(width: 10),
        Text(
          "$label: ",
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildNotLoggedInUI() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle_rounded, size: 80, color: Colors.blue.withValues(alpha: 0.5)),
              const SizedBox(height: 24),
              Text(
                "请先登录",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "登录后即可管理您的账户与订阅",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Get.to(() => const SignInScreen(), transition: Transition.rightToLeft),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                ),
                child: Text("立即登录", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Get.to(() => const SignUpScreen(), transition: Transition.rightToLeft),
                child: Text("没有账号？立即注册", 
                  style: GoogleFonts.poppins(
                    fontSize: 12, 
                    color: Colors.blue, 
                    fontWeight: FontWeight.w600
                  )
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.logout_rounded, color: AppColors.appPrimaryColor, size: 50),
              const SizedBox(height: 16),
              Text(
                '退出确认',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 10),
              Text(
                '您确定要退出登录吗？',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('取消',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Get.find<AuthController>().removeUserToken();
                        Get.offAll(() => const SignInScreen(), transition: Transition.leftToRight);
                        Fluttertoast.showToast(
                          msg: "退出成功",
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('退出',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: Colors.black.withValues(alpha: 0.06),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
