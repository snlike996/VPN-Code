import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repository/v2ray_repo.dart';
import '../models/country_item.dart';
import '../models/proxy_node.dart';
import '../parser/v2ray_subscription_parser.dart';
import '../selector/node_selector.dart';
import '../speedtest/windows_real_tester.dart';
import 'onboarding_state.dart';

class OnboardingController extends ChangeNotifier {
  static const String _completedKey = 'win_onboarding_completed';
  static const String _versionKey = 'win_onboarding_version';
  static const String _lastUserKey = 'win_onboarding_last_user';

  final V2rayVpnRepo repo;
  final SharedPreferences prefs;
  final Future<bool> Function(ProxyNode node) connector;
  final int samplePerCountry;
  final int maxSamples;
  final Duration timeout;
  final String version;

  OnboardingController({
    required this.repo,
    required this.prefs,
    required this.connector,
    this.samplePerCountry = 3,
    this.maxSamples = 20,
    this.timeout = const Duration(milliseconds: 1200),
    this.version = '1',
  });

  OnboardingState _state = OnboardingState.idle();
  OnboardingState get state => _state;

  bool _running = false;
  bool _cancelled = false;
  List<ProxyNode> _rankedNodes = [];
  int _bestIndex = 0;

  ProxyNode? get bestNode => _rankedNodes.isEmpty ? null : _rankedNodes[_bestIndex];

  bool get isActive => _state.step != OnboardingStep.idle && _state.step != OnboardingStep.done;

  Future<bool> startIfNeeded({String? userId}) async {
    final completed = prefs.getBool(_completedKey) ?? false;
    final storedVersion = prefs.getString(_versionKey);
    final storedUser = prefs.getString(_lastUserKey);
    if (completed && storedVersion == version && (userId == null || storedUser == userId)) {
      return false;
    }
    await start(userId: userId);
    return true;
  }

  Future<void> start({String? userId}) async {
    if (_running) {
      return;
    }
    _running = true;
    _cancelled = false;
    _rankedNodes = [];
    _bestIndex = 0;
    _setState(
      step: OnboardingStep.fetchingSubscription,
      progress: 0.05,
      message: '正在拉取订阅列表...',
      error: null,
      lastResult: null,
    );

    try {
      final countries = await _fetchCountriesWithRetry();
      if (_cancelled) {
        _setIdle();
        return;
      }
      if (countries.isEmpty) {
        _fail('订阅列表为空');
        return;
      }

      final selected = _selectPrimaryCountry(countries);
      _setState(
        step: OnboardingStep.parsingNodes,
        progress: 0.25,
        message: '正在拉取 ${selected.name} 订阅...',
        subscriptionSource: selected.code,
        countryCount: countries.length,
      );

      final content = await _fetchSubscriptionWithRetry(selected.code);
      if (_cancelled) {
        _setIdle();
        return;
      }
      if (content == null || content.trim().isEmpty) {
        _fail('订阅内容为空');
        return;
      }

      _setState(
        step: OnboardingStep.parsingNodes,
        progress: 0.4,
        message: '正在解析节点...',
      );

      final nodes = V2raySubscriptionParser.parse(content);
      if (nodes.isEmpty) {
        _fail('订阅无可用节点');
        return;
      }

      _setState(
        step: OnboardingStep.speedTesting,
        progress: 0.55,
        message: '正在测速节点...',
        nodeCount: nodes.length,
      );

      final samples = _sampleNodesByCountry({
        selected.code: nodes,
      });
      if (samples.isEmpty) {
        _fail('没有可测速的节点');
        return;
      }

      final sorted = await WindowsRealTester.testAndSort(
        samples,
        timeout: timeout,
      );
      if (_cancelled) {
        _setIdle();
        return;
      }

      _rankedNodes = sorted;
      _bestIndex = 0;
      _setState(
        step: OnboardingStep.pickingBest,
        progress: 0.75,
        message: '正在推荐最佳节点...',
      );

      final best = NodeSelector.pickBest(sorted);
      if (best == null) {
        _fail('暂无可用节点');
        return;
      }

      _setState(
        step: OnboardingStep.readyToConnect,
        progress: 0.9,
        message: '准备连接最佳节点',
        bestNode: best,
      );
    } catch (e) {
      _fail('订阅流程失败: $e');
    } finally {
      _running = false;
    }
  }

  Future<void> confirmConnect() async {
    final node = bestNode ?? _state.bestNode;
    if (node == null) {
      _fail('没有可连接的节点');
      return;
    }
    _setState(
      step: OnboardingStep.connecting,
      progress: 0.95,
      message: '正在连接...',
      error: null,
    );

    try {
      final success = await connector(node);
      if (!success) {
        _fail('连接失败');
        return;
      }
      await _markCompleted(OnboardingResult.success);
      _setState(
        step: OnboardingStep.done,
        progress: 1,
        message: '连接成功',
        lastResult: OnboardingResult.success,
      );
    } catch (e) {
      _fail('连接失败: $e');
    }
  }

  void cancel() {
    _cancelled = true;
    _setState(
      step: OnboardingStep.idle,
      progress: 0,
      message: '已取消引导',
      error: null,
    );
  }

  Future<void> skip({String? userId}) async {
    await _markCompleted(OnboardingResult.skipped, userId: userId);
    _setState(
      step: OnboardingStep.skipped,
      progress: 1,
      message: '已跳过引导',
      lastResult: OnboardingResult.skipped,
    );
  }

  Future<void> retry({String? userId}) async {
    await start(userId: userId);
  }

  void pickNextBest() {
    if (_rankedNodes.isEmpty) {
      return;
    }
    final limit = _rankedNodes.length < 5 ? _rankedNodes.length : 5;
    _bestIndex = (_bestIndex + 1) % limit;
    _setState(
      step: OnboardingStep.readyToConnect,
      progress: _state.progress,
      message: '已切换推荐节点',
      bestNode: _rankedNodes[_bestIndex],
      error: null,
    );
  }

  void reset() {
    _setState(step: OnboardingStep.idle, progress: 0, message: '', error: null);
  }

  Future<List<CountryItem>> _fetchCountriesWithRetry() async {
    for (var attempt = 1; attempt <= 2; attempt++) {
      final response = await repo.getCountries();
      final data = response.response?.data;
      if (response.response?.statusCode == 200 && data is List) {
        return data.map((e) => CountryItem.fromJson(e)).toList();
      }
      if (attempt == 2) {
        throw Exception(response.error ?? '国家列表获取失败');
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }
    return [];
  }

  Future<String?> _fetchSubscriptionWithRetry(String countryCode) async {
    for (var attempt = 1; attempt <= 2; attempt++) {
      final response = await repo.getSubscriptionContent(countryCode);
      if (response.response?.statusCode == 200 && response.response?.data != null) {
        return response.response!.data.toString();
      }
      if (attempt == 2) {
        final status = response.response?.statusCode;
        throw Exception(response.error ?? '订阅获取失败 (status=$status)');
      }
      await Future.delayed(const Duration(milliseconds: 400));
    }
    return null;
  }

  CountryItem _selectPrimaryCountry(List<CountryItem> countries) {
    final lastCountry = prefs.getString('win_last_country');
    if (lastCountry != null) {
      final match =
          countries.where((country) => country.code == lastCountry).toList();
      if (match.isNotEmpty) {
        return match.first;
      }
    }
    return countries.first;
  }

  List<ProxyNode> _sampleNodesByCountry(
    Map<String, List<ProxyNode>> grouped,
  ) {
    final samples = <ProxyNode>[];
    for (final entry in grouped.entries) {
      final nodes = entry.value.take(samplePerCountry).toList();
      samples.addAll(nodes);
      if (samples.length >= maxSamples) {
        break;
      }
    }
    if (samples.length > maxSamples) {
      return samples.sublist(0, maxSamples);
    }
    return samples;
  }

  Future<void> _markCompleted(OnboardingResult result, {String? userId}) async {
    await prefs.setBool(_completedKey, true);
    await prefs.setString(_versionKey, version);
    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_lastUserKey, userId);
    }
  }

  void _setState({
    OnboardingStep? step,
    double? progress,
    String? message,
    String? error,
    String? subscriptionSource,
    int? countryCount,
    int? nodeCount,
    ProxyNode? bestNode,
    OnboardingResult? lastResult,
  }) {
    _state = _state.copyWith(
      step: step,
      progress: progress,
      message: message,
      error: error,
      subscriptionSource: subscriptionSource,
      countryCount: countryCount,
      nodeCount: nodeCount,
      bestNode: bestNode,
      lastResult: lastResult,
    );
    if (kDebugMode) {
      log('Onboarding step=${_state.step} message=${_state.message}');
    }
    notifyListeners();
  }

  void _fail(String message) {
    _setState(
      step: OnboardingStep.failed,
      progress: _state.progress,
      message: '引导失败',
      error: message,
      lastResult: OnboardingResult.failure,
    );
  }

  void _setIdle() {
    _setState(step: OnboardingStep.idle, progress: 0, message: '');
  }
}
