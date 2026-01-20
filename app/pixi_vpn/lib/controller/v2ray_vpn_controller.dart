import 'dart:developer';
import 'package:get/get.dart';
import 'package:pixi_vpn/data/repository/v2ray_repo.dart';
import 'package:pixi_vpn/model/country_item.dart';
import 'package:pixi_vpn/model/proxy_node.dart';
import 'package:pixi_vpn/utils/v2ray_subscription_parser.dart';
import '../data/model/base_model/api_response.dart';

class V2rayVpnController extends GetxController {
  final V2rayVpnRepo v2rayVpnRepo;

  V2rayVpnController({
    required this.v2rayVpnRepo,
  });

  bool _isLoadingCountries = false;
  bool get isLoadingCountries => _isLoadingCountries;

  bool _isLoadingNodes = false;
  bool get isLoadingNodes => _isLoadingNodes;

  String? countriesError;
  String? nodesError;

  List<CountryItem> _countries = [];
  List<CountryItem> get countries => _countries;

  List<ProxyNode> _vpnServers = [];
  List<ProxyNode> get vpnServers => _vpnServers;

  void setVpnServers(List<ProxyNode> servers) {
    _vpnServers = servers;
    update();
  }

  Future<void> getCountries() async {
    _isLoadingCountries = true;
    countriesError = null;
    update();

    ApiResponse apiResponse = await v2rayVpnRepo.getCountries();

    _isLoadingCountries = false;

    if (apiResponse.response != null) {
      final status = apiResponse.response!.statusCode;
      final data = apiResponse.response!.data;
      final body = data == null ? '' : data.toString();
      final preview = body.length > 100 ? body.substring(0, 100) : body;
      log('Countries response status=$status length=${body.length} preview="$preview"');
    } else {
      final err = apiResponse.error?.toString() ?? 'unknown error';
      log('Countries request failed: $err');
    }

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        apiResponse.response!.data != null) {
      try {
        final data = apiResponse.response!.data;
        if (data is List) {
          _countries = data.map((e) => CountryItem.fromJson(e)).toList();
        } else {
          _countries = [];
        }
      } catch (e) {
        _countries = [];
        countriesError = '国家列表解析失败';
        log('Failed to parse country list: $e');
      }
    } else {
      _countries = [];
      final status = apiResponse.response?.statusCode;
      final err = apiResponse.error?.toString();
      countriesError = err == null
          ? '国家列表加载失败'
          : '国家列表加载失败: $err';
      log('Failed to load countries. Status: $status Error: $err');
    }

    update();
  }

  Future<void> loadCountryNodes(String countryCode) async {
    _isLoadingNodes = true;
    nodesError = null;
    update();

    log('Loading subscription for country=$countryCode');
    ApiResponse apiResponse = await v2rayVpnRepo.getSubscriptionContent(countryCode);

    _isLoadingNodes = false;

    if (apiResponse.response != null) {
      final status = apiResponse.response!.statusCode;
      final data = apiResponse.response!.data;
      final body = data == null ? '' : data.toString();
      final preview = body.length > 100 ? body.substring(0, 100) : body;
      log('Subscription response status=$status length=${body.length} preview="$preview"');
    } else {
      log('Subscription response missing');
    }

    if (apiResponse.response != null &&
        apiResponse.response!.statusCode == 200 &&
        apiResponse.response!.data != null) {
      try {
        final data = apiResponse.response!.data;
        final content = data is String ? data : data.toString();
        _vpnServers = V2raySubscriptionParser.parse(content);
      } catch (e) {
        _vpnServers = [];
        nodesError = '订阅解析失败';
        log('Failed to parse subscription content: $e');
      }
    } else {
      _vpnServers = [];
      if (apiResponse.response?.statusCode == 403) {
        nodesError = '订阅未启用或无权限';
      } else if (apiResponse.response?.statusCode == 404) {
        nodesError = '未找到订阅配置';
      } else {
        nodesError = '订阅加载失败';
      }
      log('Failed to load subscription. Status: ${apiResponse.response?.statusCode}');
    }

    update();
  }
}
