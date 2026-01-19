import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get_it/get_it.dart';
import 'package:pixi_vpn/controller/active_server_controller.dart';
import 'package:pixi_vpn/controller/app_setting_controller.dart';
import 'package:pixi_vpn/controller/app_update_controller.dart';
import 'package:pixi_vpn/controller/chat_controller.dart';
import 'package:pixi_vpn/controller/contact_controller.dart';
import 'package:pixi_vpn/controller/general_setting_controller.dart';
import 'package:pixi_vpn/controller/help_center_controller.dart';
import 'package:pixi_vpn/controller/open_vpn_controller.dart';
import 'package:pixi_vpn/controller/v2ray_vpn_controller.dart';
import 'package:pixi_vpn/controller/wg_client_controller.dart';
import 'package:pixi_vpn/controller/wireguard_vpn_controller.dart';
import 'package:pixi_vpn/data/repository/active_server_repo.dart';
import 'package:pixi_vpn/data/repository/app_setting_repo.dart';
import 'package:pixi_vpn/data/repository/app_update_repo.dart';
import 'package:pixi_vpn/data/repository/chat_repo.dart';
import 'package:pixi_vpn/data/repository/contact_repo.dart';
import 'package:pixi_vpn/data/repository/genral_setting_repo.dart';
import 'package:pixi_vpn/data/repository/help_center_repo.dart';
import 'package:pixi_vpn/data/repository/open_vpn_repo.dart';
import 'package:pixi_vpn/data/repository/v2ray_repo.dart';
import 'package:pixi_vpn/data/repository/wg_client_repo.dart';
import 'package:pixi_vpn/data/repository/wireguard_vpn_repo.dart';
import 'package:pixi_vpn/utils/app_strings.dart';
import 'package:pixi_vpn/utils/ping_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controller/auth_controller.dart';
import 'controller/profile_controller.dart';
import 'controller/user_status_controller.dart';
import 'data/datasource/remote/dio/dio_client.dart';
import 'data/datasource/remote/dio/logging_interceptor.dart';
import 'data/repository/auth_repo.dart';
import 'data/repository/profile_repo.dart';
import 'data/repository/user_status_repo.dart';

final sl = GetIt.instance;

Future<void> init() async {
  /// Core
  sl.registerLazySingleton(() => DioClient(AppStrings.baseUrl, sl(), loggingInterceptor: sl(), sharedPreferences: sl()));

  ///Repository
  sl.registerLazySingleton<FlutterSecureStorage>(() => FlutterSecureStorage());
  sl.registerLazySingleton(() => AuthRepo(dioClient: sl(), secureStorage: sl()));
  sl.registerLazySingleton(() => V2rayVpnRepo(dioClient: sl(), secureStorage: sl()));
  sl.registerLazySingleton(() => OpenVpnRepo(dioClient: sl(), secureStorage: sl()));
  sl.registerLazySingleton(() => WireGuardVpnRepo(dioClient: sl(), secureStorage: sl()));
  sl.registerLazySingleton(() => HelpCenterRepo(dioClient: sl(), secureStorage: sl()));
  sl.registerLazySingleton(() => ChatRepo(dioClient: sl(), secureStorage: sl()));
  sl.registerLazySingleton(() => ProfileRepo(dioClient: sl(), secureStorage: sl()));
  sl.registerLazySingleton(() => UserStatusRepo(dioClient: sl(), secureStorage: sl()));
  sl.registerLazySingleton(() => AppUpdateRepo(dioClient: sl(), secureStorage: sl()));
  sl.registerLazySingleton(() => SettingRepo(dioClient: sl(), secureStorage: sl()));
  sl.registerLazySingleton(() => ContactRepo(dioClient: sl(), secureStorage: sl()));
  sl.registerLazySingleton(() => GeneralSettingRepo(dioClient: sl(), secureStorage: sl()));
  sl.registerLazySingleton(() => ActiveServerRepo(dioClient: sl(), secureStorage: sl()));
  sl.registerLazySingleton(() => WgClientRepo(dioClient: sl(), secureStorage: sl()));

  /// Utils
  sl.registerLazySingleton(() => PingService(dio: sl()));

  /// Controller
  Get.lazyPut(() => AuthController(authRepo: sl(), dioClient: sl()), fenix: true);
  Get.lazyPut(() => V2rayVpnController(v2rayVpnRepo: sl(), pingService: sl()), fenix: true);
  Get.lazyPut(() => OpenVpnController(openVpnRepo: sl()), fenix: true);
  Get.lazyPut(() => WireGuardVpnController(wireGuardVpnRepo: sl()), fenix: true);
  Get.lazyPut(() => HelpCenterController(helpCenterRepo: sl()), fenix: true);
  Get.lazyPut(() => ChatController(chatRepo: sl()), fenix: true);
  Get.lazyPut(() => ProfileController(profileRepo: sl()), fenix: true);
  Get.lazyPut(() => UserStatusController(userStatusRepo: sl()), fenix: true);
  Get.lazyPut(() => AppSettingController(settingRepo: sl()), fenix: true);
  Get.lazyPut(() => AppUpdateController(appUpdateRepo: sl()), fenix: true);
  Get.lazyPut(() => ContactController(contactRepo: sl()), fenix: true);
  Get.lazyPut(() => GeneralSettingController(generalSettingRepo: sl()), fenix: true);
  Get.lazyPut(() => ActiveServerController(activeServerRepo: sl()), fenix: true);
  Get.lazyPut(() => WgClientController(wgClientRepo: sl()), fenix: true);


  /// External pocket lock
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => LoggingInterceptor());
}
