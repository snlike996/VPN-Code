import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/connection/connection_controller.dart';
import '../core/models/proxy_node.dart';
import '../core/onboarding/onboarding_controller.dart';
import '../core/onboarding/onboarding_state.dart';
import '../data/repository/v2ray_repo.dart';
import '../di_container.dart' as di;
import '../ui/shared/auth/sign_up_screen.dart';
import '../ui/shared/auth/signin_screen.dart';
import 'first_run_controller.dart';
import 'first_run_state.dart';

class FirstRunFlowPage extends StatefulWidget {
  final FirstRunController controller;
  final ConnectionController connectionController;

  const FirstRunFlowPage({
    super.key,
    required this.controller,
    required this.connectionController,
  });

  @override
  State<FirstRunFlowPage> createState() => _FirstRunFlowPageState();
}

class _FirstRunFlowPageState extends State<FirstRunFlowPage>
    with WindowListener {
  OnboardingController? _onboardingController;
  StreamSubscription? _onboardingSub;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.setPreventClose(false);
    _initOnboarding();
  }

  @override
  void dispose() {
    _onboardingSub?.cancel();
    _onboardingController?.removeListener(_handleOnboardingChange);
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await windowManager.destroy();
  }

  Future<void> _initOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    _onboardingController = OnboardingController(
      repo: di.sl<V2rayVpnRepo>(),
      prefs: prefs,
      connector: _connectFromOnboarding,
    )..addListener(_handleOnboardingChange);
    setState(() {});
  }

  Future<bool> _connectFromOnboarding(ProxyNode node) async {
    try {
      await widget.connectionController.connect(node, silent: false);
      return widget.connectionController.status.value ==
          ConnectionStatus.connected;
    } catch (_) {
      return false;
    }
  }

  void _handleOnboardingChange() {
    final controller = _onboardingController;
    if (controller == null) {
      return;
    }
    final step = controller.state.step;
    if (step == OnboardingStep.done) {
      widget.controller.markCompleted();
    }
  }

  Future<void> _handleEscape() async {
    final stage = widget.controller.state.stage;
    if (stage == FirstRunStage.onboarding) {
      final skip = await _confirmSkip(context);
      if (skip) {
        await widget.controller.skipFirstRun();
      }
      return;
    }
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.escape): const ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<Intent>(
            onInvoke: (_) {
              _handleEscape();
              return null;
            },
          ),
        },
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final stage = widget.controller.state.stage;
            switch (stage) {
              case FirstRunStage.welcome:
                return _WelcomePage(
                  onStart: widget.controller.goToAuthChoice,
                  onExit: () => windowManager.destroy(),
                );
              case FirstRunStage.authChoice:
                return _AuthChoicePage(
                  onLogin: widget.controller.goToLogin,
                  onRegister: widget.controller.goToRegister,
                  onSkip: () => widget.controller.skipFirstRun(),
                  onExit: () => windowManager.destroy(),
                );
              case FirstRunStage.login:
                return SignInScreen(
                  showBack: true,
                  showExit: true,
                  onBack: widget.controller.goToAuthChoice,
                  onRegisterTap: widget.controller.goToRegister,
                  onExit: () => windowManager.destroy(),
                  onLoginSuccess: widget.controller.goToOnboarding,
                );
              case FirstRunStage.register:
                return SignUpScreen(
                  showBack: true,
                  showExit: true,
                  onBack: widget.controller.goToAuthChoice,
                  onExit: () => windowManager.destroy(),
                  onLoginTap: widget.controller.goToLogin,
                  onRegisterSuccess: widget.controller.goToOnboarding,
                );
              case FirstRunStage.onboarding:
                return _OnboardingFlowPage(
                  controller: _onboardingController,
                  onSkip: () => widget.controller.skipFirstRun(),
                  onCancel: () => widget.controller.goToAuthChoice(),
                );
              case FirstRunStage.completed:
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
            }
          },
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onExit;

  const _WelcomePage({
    required this.onStart,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TSVPN',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  '安全、稳定的跨境网络连接',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onStart,
                    child: const Text('开始使用'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: onExit,
                  child: const Text('退出'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthChoicePage extends StatelessWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback onSkip;
  final VoidCallback onExit;

  const _AuthChoicePage({
    required this.onLogin,
    required this.onRegister,
    required this.onSkip,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '欢迎使用 TSVPN',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onLogin,
                    child: const Text('登录'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onRegister,
                    child: const Text('注册'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: onSkip,
                  child: const Text('跳过（只读模式）'),
                ),
                TextButton(
                  onPressed: onExit,
                  child: const Text('退出'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingFlowPage extends StatefulWidget {
  final OnboardingController? controller;
  final VoidCallback onSkip;
  final VoidCallback onCancel;

  const _OnboardingFlowPage({
    required this.controller,
    required this.onSkip,
    required this.onCancel,
  });

  @override
  State<_OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends State<_OnboardingFlowPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = widget.controller;
    if (controller != null && controller.state.step == OnboardingStep.idle) {
      Future<void>.microtask(controller.start);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final state = controller.state;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '首次自动配置',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: state.progress.clamp(0, 1)),
                    const SizedBox(height: 16),
                    Text(_stepLabel(state.step),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (state.message.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(state.message),
                    ],
                    if (state.bestNode != null &&
                        state.step == OnboardingStep.readyToConnect) ...[
                      const SizedBox(height: 16),
                      Text('推荐节点: ${state.bestNode!.displayName}'),
                    ],
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _buildActions(controller, state),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildActions(
    OnboardingController controller,
    OnboardingState state,
  ) {
    final actions = <Widget>[];
    if (state.step == OnboardingStep.readyToConnect) {
      actions.add(
        TextButton(
          onPressed: controller.pickNextBest,
          child: const Text('换一个'),
        ),
      );
      actions.add(
        ElevatedButton(
          onPressed: controller.confirmConnect,
          child: const Text('一键连接'),
        ),
      );
    } else if (state.step == OnboardingStep.failed) {
      actions.add(
        TextButton(
          onPressed: controller.retry,
          child: const Text('重试'),
        ),
      );
    }

    actions.add(
      TextButton(
        onPressed: widget.onSkip,
        child: const Text('跳过'),
      ),
    );
    actions.add(
      TextButton(
        onPressed: widget.onCancel,
        child: const Text('取消'),
      ),
    );

    return actions;
  }

  String _stepLabel(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.fetchingSubscription:
        return '获取订阅';
      case OnboardingStep.parsingNodes:
        return '解析节点';
      case OnboardingStep.speedTesting:
        return '节点测速';
      case OnboardingStep.pickingBest:
        return '推荐节点';
      case OnboardingStep.readyToConnect:
        return '准备连接';
      case OnboardingStep.connecting:
        return '正在连接';
      case OnboardingStep.failed:
        return '配置失败';
      case OnboardingStep.done:
        return '完成';
      case OnboardingStep.skipped:
        return '已跳过';
      case OnboardingStep.idle:
      default:
        return '准备中';
    }
  }
}

Future<bool> _confirmSkip(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('跳过引导？'),
      content: const Text('跳过后将直接进入主界面，稍后可在设置中重新运行。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('跳过'),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}
