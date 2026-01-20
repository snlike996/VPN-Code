import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../controller/auth_controller.dart';
import 'first_run_state.dart';

class FirstRunController extends ChangeNotifier {
  static const String completedKey = 'first_run_completed';
  static const String stageKey = 'first_run_stage';
  static const String installFingerprintKey = 'install_fingerprint';

  final SharedPreferences prefs;
  final AuthController authController;

  FirstRunState _state = const FirstRunState(
    stage: FirstRunStage.welcome,
    completed: false,
  );

  FirstRunState get state => _state;
  bool get isCompleted => _state.completed;

  FirstRunController({
    required this.prefs,
    required this.authController,
  });

  Future<void> init() async {
    await _syncInstallFingerprint();
    final completed = prefs.getBool(completedKey) ?? false;
    final storedStage = prefs.getString(stageKey);
    var stage = _parseStage(storedStage) ?? FirstRunStage.welcome;

    if (completed) {
      stage = FirstRunStage.completed;
    } else {
      final token = await authController.getAuthToken();
      if (token.isNotEmpty &&
          (stage == FirstRunStage.login ||
              stage == FirstRunStage.register ||
              stage == FirstRunStage.authChoice ||
              stage == FirstRunStage.welcome)) {
        stage = FirstRunStage.onboarding;
      }
    }

    _setState(stage: stage, completed: completed);
  }

  Future<void> _syncInstallFingerprint() async {
    if (kIsWeb || !Platform.isWindows) {
      return;
    }
    final current = await _currentInstallFingerprint();
    if (current == null) {
      return;
    }
    final stored = prefs.getString(installFingerprintKey);
    if (stored == null || stored != current) {
      await authController.removeUserToken();
      await prefs.setBool(completedKey, false);
      await prefs.setString(stageKey, FirstRunStage.welcome.name);
      await prefs.setString(installFingerprintKey, current);
    }
  }

  Future<String?> _currentInstallFingerprint() async {
    try {
      final exe = File(Platform.resolvedExecutable);
      if (!await exe.exists()) {
        return null;
      }
      final stat = await exe.stat();
      return '${exe.path}|${stat.size}|${stat.modified.millisecondsSinceEpoch}';
    } catch (_) {
      return null;
    }
  }

  void goToWelcome() => _setStage(FirstRunStage.welcome);

  void goToAuthChoice() => _setStage(FirstRunStage.authChoice);

  void goToLogin() => _setStage(FirstRunStage.login);

  void goToRegister() => _setStage(FirstRunStage.register);

  void goToOnboarding() => _setStage(FirstRunStage.onboarding);

  Future<void> markCompleted() async {
    await prefs.setBool(completedKey, true);
    await prefs.setString(stageKey, FirstRunStage.completed.name);
    _setState(stage: FirstRunStage.completed, completed: true);
  }

  Future<void> skipFirstRun() async {
    await markCompleted();
  }

  void reset() {
    prefs.remove(completedKey);
    prefs.remove(stageKey);
    _setState(stage: FirstRunStage.welcome, completed: false);
  }

  FirstRunStage? _parseStage(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    for (final stage in FirstRunStage.values) {
      if (stage.name == value) {
        return stage;
      }
    }
    return null;
  }

  void _setStage(FirstRunStage stage) {
    prefs.setString(stageKey, stage.name);
    _setState(stage: stage, completed: false);
  }

  void _setState({
    required FirstRunStage stage,
    required bool completed,
  }) {
    _state = _state.copyWith(stage: stage, completed: completed);
    if (kDebugMode) {
      log('FirstRun stage=${_state.stage} completed=${_state.completed}');
    }
    notifyListeners();
  }
}
