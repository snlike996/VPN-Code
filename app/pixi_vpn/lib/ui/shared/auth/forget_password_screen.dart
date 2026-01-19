import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixi_vpn/controller/auth_controller.dart';
import 'package:pixi_vpn/utils/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(
      builder: (authController) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 1,
            ),
          ),
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        '忘记密码',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.appPrimaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          '请输入您的邮箱，我们将发送验证码以恢复您的密码',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      '邮箱',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "请输入邮箱";
                        }
                        // Email regex check
                        bool emailValid = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value);
                        if (!emailValid) {
                          return "请输入有效的邮箱";
                        }
                        return null;
                      },
                      controller: _emailController,
                      decoration: InputDecoration(
                        hintText: '输入邮箱',
                        hintStyle: TextStyle(color: Colors.grey.shade700),
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
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {

                            final email = _emailController.text.trim();

                            authController.forgetPassword(email: email);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.appPrimaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child:
                        authController.isLoadingForget==false?
                        Text(
                          '提交',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ):
                        SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white)
                            )
                        )
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '返回 ',
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child:  Text(
                              '登录',
                              style: GoogleFonts.poppins(
                                color: AppColors.appPrimaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
        );
      }
    );
  }
}