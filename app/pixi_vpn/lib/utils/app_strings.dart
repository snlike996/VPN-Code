class AppStrings{

  //API BASE URL
  static const String baseUrl = "https://dom.cc.cd/";
  static const String tokenKey = 'auth_token';

  //API ENDPOINTS
  static const String v2rayUrl = "/api/v2ray/list";
  static const String wireGuardVpUrl = "/api/wireguard/list";
  static const String openVpnUrl = "/api/openvpn/list";
  static const String helpCenterUrl = "/api/helpcenter/search";
  static const String loginUrl = "/api/auth/user/login";
  static const String registerUrl = "/api/auth/user/register";
  static const String forgetPasswordUrl = "/api/user/forgot-password";
  static const String resetPasswordUrl = "/api/user/reset-password";
  static const String profileUrl = "/api/user/show-profile";
  static const String subscriptionUrl = "/api/user/subscription";
  static const String userStatusUrl = "/api/user/status";
  static const String subscriptionCancelUrl = "/api/user/subscription/cancel";
  static const String chatUrl = "/api/user/chat";
  static const String appUpdateUrl = "/api/popup-setting";
  static const String appContactUrl = "/api/contact-setting";
  static const String appGeneralSettingUrl = "/api/general-setting";
  static const String appSettingUrl = "/api/app-setting";
  static const String admobUrl = "/api/admob-setting";
  static const String serverConnect = "/api/server-connect";
  static const String serverDisConnect = "/api/server-disconnect";
  static const String wireGuardClientGenerate = "/api/vpn/generate";
  static const String wireGuardClientRemove = "/api/vpn/remove-client";

}