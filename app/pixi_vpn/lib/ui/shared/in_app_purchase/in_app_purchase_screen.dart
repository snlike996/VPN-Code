import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controller/profile_controller.dart';

class InAppPurchaseScreen extends StatefulWidget {
  const InAppPurchaseScreen({super.key});

  @override
  State<InAppPurchaseScreen> createState() => _InAppPurchaseScreenState();
}

class _InAppPurchaseScreenState extends State<InAppPurchaseScreen> {
  final TextEditingController _redeemCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final profileController = Get.find<ProfileController>();
    profileController.getRedeemStatus();
    profileController.getProfileData();
  }

  @override
  void dispose() {
    _redeemCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (profileController) {
        final data = profileController.profileData;
        final isPremium = data != null && (data["isPremium"] ?? 0) == 1;
        final remainingDays = data != null ? _remainingDays(data["expired_date"]) : null;
        final hasPending = profileController.hasPendingRedeem;

        return Scaffold(
          backgroundColor: const Color(0xFFF8F8F8),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 10,
            leading: IconButton(
              onPressed: () {
                Get.back();
              },
              icon: const Icon(
                Icons.arrow_back,
                color: Colors.black,
              ),
            ),
            centerTitle: true,
            title: Text(
              "口令红包",
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 16,
                letterSpacing: 0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                _buildPlanCard(hasPending, isPremium, remainingDays),
                const SizedBox(height: 18),
                _buildRedeemForm(profileController, hasPending),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlanCard(bool hasPending, bool isPremium, int? remainingDays) {
    String subtitleText;
    if (hasPending) {
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
      ),
    );
  }

  Widget _buildRedeemForm(ProfileController profileController, bool hasPending) {
    if (hasPending) {
      return Container(
        decoration: _cardDecoration(),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            "等待验证",
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
        ),
      );
    }

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "填写支付宝口令红包",
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _redeemCodeController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: "请输入口令红包",
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasPending || profileController.isRedeemSubmitting
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
                        _redeemCodeController.clear();
                        await profileController.getRedeemStatus();
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
                      hasPending ? "等待验证" : "提交",
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
