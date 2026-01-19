import 'dart:io';
import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixi_vpn/controller/auth_controller.dart';
import 'package:pixi_vpn/ui/shared/auth/sign_up_screen.dart';
import 'package:pixi_vpn/utils/app_colors.dart';
import 'forget_password_screen.dart';


class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final _formKey = GlobalKey<FormState>();

  String? deviceId;

  Future<String?> getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      var iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    } else if (Platform.isAndroid) {
      return const AndroidId().getId();
    } else if (Platform.isMacOS) {
      var macOsInfo = await deviceInfo.macOsInfo;
      return macOsInfo.systemGUID ?? macOsInfo.model;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    loadDeviceId();
  }

  loadDeviceId() async {
    deviceId = await getDeviceId();
    deviceId ??= "unknown_device";
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        return Scaffold(
          // White background for the whole screen
          backgroundColor: Colors.white,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 1,
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 48,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          // Title
                          Center(
                            child: Text(
                              '登录',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.appPrimaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),

                          // Email label
                          Text(
                            '邮箱',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Email field
                          TextFormField(
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty) return '请输入邮箱';
                              // Simple, commonly used email regex (anchored to end of string)
                              final emailRegex = RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');
                              if (!emailRegex.hasMatch(value)) return '请输入有效的邮箱';
                              return null;
                            },
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: '输入邮箱',
                              hintStyle: TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: const Color(0xFFF6F8FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Password label
                          Text(
                            '密码',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Password field
                          TextFormField(
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            validator: (value) {
                              if (value == null || value.isEmpty) return '请输入密码';
                              // Password must contain upper, lower, digit, special char and be at least 8 chars
                              final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@\$!%*?&]).{8,}$');
                              if (!passwordRegex.hasMatch(value)) {
                                return '密码必须至少8位，包含大小写字母、数字和符号';
                              }
                              return null;
                            },
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: '输入密码',
                              hintStyle: TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: const Color(0xFFF6F8FA),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey.shade600,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Get.to(()=> ForgotPasswordScreen(),transition: Transition.fadeIn);
                              },
                              child: Text(
                                '忘记密码？',
                                style: TextStyle(
                                  color: AppColors.appPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Sign In button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState?.validate() ?? false) {

                                  final email = _emailController.text.trim();
                                  final password = _passwordController.text.trim();

                                  authController.login(email: email, password: password, deviceId: deviceId ?? 'unknown_device');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.appPrimaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 0,
                              ),
                              child: authController.isLoadingLogin == false
                                  ? Text(
                                      '登录',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    )
                                  : SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                 Text(
                                  "还没有账号？ ",
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const SignUpScreen(),
                                      ),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child:  Text(
                                    '注册',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.appPrimaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }
}

