import 'package:flutter/material.dart';

import '../../../core/onboarding/onboarding_controller.dart';
import '../../../core/onboarding/onboarding_state.dart';

class OnboardingWizard extends StatelessWidget {
  final OnboardingController controller;
  final VoidCallback onClose;

  const OnboardingWizard({
    super.key,
    required this.controller,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        if (state.step == OnboardingStep.idle) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 6,
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '首次体验引导',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      tooltip: '关闭',
                      onPressed: onClose,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: state.progress.clamp(0, 1)),
                const SizedBox(height: 12),
                Text(
                  _stepLabel(state.step),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (state.message.isNotEmpty)
                  Text(state.message, style: const TextStyle(fontSize: 12)),
                if (state.subscriptionSource != null) ...[
                  const SizedBox(height: 8),
                  Text('订阅来源: ${state.subscriptionSource}', style: const TextStyle(fontSize: 12)),
                ],
                if (state.countryCount > 0 || state.nodeCount > 0) ...[
                  const SizedBox(height: 8),
                  Text('国家: ${state.countryCount}  节点: ${state.nodeCount}',
                      style: const TextStyle(fontSize: 12)),
                ],
                if (state.bestNode != null && state.step == OnboardingStep.readyToConnect) ...[
                  const SizedBox(height: 12),
                  const Text('推荐节点', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(state.bestNode!.displayName, style: const TextStyle(fontSize: 12)),
                ],
                if (state.error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.error!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 16),
                _buildActions(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context, OnboardingState state) {
    final actions = <Widget>[];

    final canCancel = state.step != OnboardingStep.connecting &&
        state.step != OnboardingStep.done &&
        state.step != OnboardingStep.skipped;
    if (canCancel) {
      actions.add(
        TextButton(
          onPressed: controller.cancel,
          child: const Text('取消'),
        ),
      );
    }

    if (state.step == OnboardingStep.failed) {
      actions.add(
        TextButton(
          onPressed: controller.retry,
          child: const Text('重试'),
        ),
      );
    }

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
    }

    if (state.step != OnboardingStep.done && state.step != OnboardingStep.skipped) {
      actions.add(
        TextButton(
          onPressed: controller.skip,
          child: const Text('跳过'),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: actions,
    );
  }

  String _stepLabel(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.fetchingSubscription:
        return '拉取订阅';
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
      case OnboardingStep.done:
        return '完成';
      case OnboardingStep.failed:
        return '失败';
      case OnboardingStep.skipped:
        return '已跳过';
      case OnboardingStep.idle:
      default:
        return '待开始';
    }
  }
}
