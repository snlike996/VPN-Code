import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:pixi_vpn/ui/shared/home/v2_home_screen.dart';
import 'package:pixi_vpn/ui/shared/auth/signin_screen.dart';
import '../data/datasource/remote/dio/dio_client.dart';
import '../data/model/base_model/api_response.dart';
import '../data/repository/auth_repo.dart';
import '../ui/shared/auth/reset_password_screen.dart';

class AuthController extends GetxController {
  final DioClient dioClient;
  final AuthRepo authRepo;

  AuthController({
    required this.authRepo,
    required this.dioClient,
  });

  bool isLoadingLogin = false;
  bool isLoadingRegister = false;
  bool isLoadingForget = false;
  bool isLoadingReset = false;

  var rememberMe = false.obs;

  void _showToast({required String msg, required bool isSuccess}) {
    // Use Get.snackbar for cross-platform support (Fluttertoast often fails on desktop)
    Get.snackbar(
      isSuccess ? "成功" : "错误",
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isSuccess ? Colors.green : Colors.red,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
      duration: const Duration(seconds: 3),
    );
  }

  // ================= REGISTER =================

  register({
    required String email,
    required String name,
    required String password,
  }) async {
    isLoadingRegister = true;
    update();

    try {
      final ApiResponse apiResponse = await authRepo.register(
        name: name,
        email: email,
        password: password,
      );

      final response = apiResponse.response;

      if (response != null && response.statusCode == 201) {
        final Map<String, dynamic> data = response.data;
        final String? token = data["token"];
        // final String? message = data["massage"]; 

        final success = token != null && token.isNotEmpty;

        _showToast(
          msg: success ? "注册成功" : "发生错误或用户数据无效",
          isSuccess: success,
        );

        if (success && token != null && token.isNotEmpty) {
          await authRepo.saveUserToken(token);
          return apiResponse.response!.statusCode;
        }
      } else {
        _showToast(msg: "发生错误或用户数据无效", isSuccess: false);
      }

    } catch (e) {
      _showToast(msg: "发生错误或用户数据无效", isSuccess: false);
    } finally {
      isLoadingRegister = false;
      update();
    }
  }

  // ================= LOGIN =================

  Future<void> login({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    isLoadingLogin = true;
    update();

    try {
      final ApiResponse apiResponse = await authRepo.login(
        email: email,
        password: password,
        deviceId: deviceId,
      );

      final response = apiResponse.response;

      if (response != null && response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final String? token = data["token"];
        // final String? message = data["message"];

        final success = token != null && token.isNotEmpty;

        _showToast(
          msg: success ? "登录成功" : "发生错误或用户数据无效",
          isSuccess: success,
        );

        if (success && token != null && token.isNotEmpty) {
          await authRepo.saveUserToken(token);

          // Navigate based on selected protocol
          await _navigateToSelectedProtocol();
        }
      } else {
        _showToast(msg: "发生错误或用户数据无效", isSuccess: false);
      }
    } catch (e) {
      if (kDebugMode) print('Login Error: $e');
      _showToast(msg: "登录失败: $e", isSuccess: false);
    } finally {
      isLoadingLogin = false;
      update();
    }
  }

  forgetPassword({dynamic email}) async {
    isLoadingForget = true;
    update();

    try {
      ApiResponse apiResponse = await authRepo.forgetPassword(email: email);

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        isLoadingForget = false;

        _showToast(msg: "请检查您的电子邮件收件箱", isSuccess: true);

        Get.to(()=> const ResetPasswordScreen(),transition: Transition.leftToRight);

      } else {
        isLoadingForget = false;
        update();
        if (apiResponse.response != null) {
          // If the status code is not 200, show an error
          _showToast(msg: "发生错误或用户数据无效", isSuccess: false);

        } else {
          isLoadingForget = false;
          // If there's no response or network error
          _showToast(msg: "发生错误或用户数据无效", isSuccess: false);
        }
      }

    } catch (e) {
      // General catch block for any unexpected errors
      isLoadingForget = false;
      update();
      if (kDebugMode) {
        print("Unexpected error: $e");
      }
      _showToast(msg: "发生错误或用户数据无效", isSuccess: false);
    }

    update();
  }

  resetPassword({dynamic email,dynamic token, dynamic password, dynamic confirmPassword}) async {
    isLoadingReset = true;
    update();

    try {
      ApiResponse apiResponse = await authRepo.resetPassword(email: email,token: token,password: password,confirmPassword: confirmPassword);

      if (apiResponse.response != null && apiResponse.response!.statusCode == 200) {
        isLoadingReset = false;
        _showToast(msg: "密码重置成功", isSuccess: true);

        Get.to(()=> const SignInScreen(),transition: Transition.leftToRight);

      } else {
        isLoadingReset = false;
        update();
        if (apiResponse.response != null) {
          // If the status code is not 200, show an error
          _showToast(msg: "发生错误或用户数据无效", isSuccess: false);
        } else {
          isLoadingReset = false;
          // If there's no response or network error
          _showToast(msg: "发生错误或用户数据无效", isSuccess: false);
        }
      }

    } catch (e) {
      // General catch block for any unexpected errors
      isLoadingReset = false;
      update();
      if (kDebugMode) {
        print("Unexpected error: $e");
      }
      _showToast(msg: "发生错误或用户数据无效", isSuccess: false);
    }

    update();
  }


  // ================= TOKEN =================

  Future<String> getUserToken() async {
    final token = await authRepo.getUserToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      update();
    });
    return token;
  }

  Future<void> removeUserToken() async {
    await authRepo.removeUserToken();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      update();
    });
  }

  Future<String> getAuthToken() async {
    final token = await authRepo.getAuthToken();
    dioClient.updateHeader(token, '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      update();
    });
    return token;
  }

  // ================= NAVIGATION =================

  Future<void> _navigateToSelectedProtocol() async {
    Get.offAll(() => const V2HomeScreen(), transition: Transition.leftToRight);
  }
}
