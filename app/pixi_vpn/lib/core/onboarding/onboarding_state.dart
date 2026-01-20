import '../models/proxy_node.dart';

enum OnboardingStep {
  idle,
  fetchingSubscription,
  parsingNodes,
  speedTesting,
  pickingBest,
  readyToConnect,
  connecting,
  done,
  failed,
  skipped,
}

enum OnboardingResult {
  success,
  failure,
  skipped,
}

class OnboardingState {
  final OnboardingStep step;
  final double progress;
  final String message;
  final String? error;
  final String? subscriptionSource;
  final int countryCount;
  final int nodeCount;
  final ProxyNode? bestNode;
  final OnboardingResult? lastResult;

  const OnboardingState({
    required this.step,
    required this.progress,
    required this.message,
    required this.error,
    required this.subscriptionSource,
    required this.countryCount,
    required this.nodeCount,
    required this.bestNode,
    required this.lastResult,
  });

  factory OnboardingState.idle() {
    return const OnboardingState(
      step: OnboardingStep.idle,
      progress: 0,
      message: '',
      error: null,
      subscriptionSource: null,
      countryCount: 0,
      nodeCount: 0,
      bestNode: null,
      lastResult: null,
    );
  }

  OnboardingState copyWith({
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
    return OnboardingState(
      step: step ?? this.step,
      progress: progress ?? this.progress,
      message: message ?? this.message,
      error: error,
      subscriptionSource: subscriptionSource ?? this.subscriptionSource,
      countryCount: countryCount ?? this.countryCount,
      nodeCount: nodeCount ?? this.nodeCount,
      bestNode: bestNode ?? this.bestNode,
      lastResult: lastResult ?? this.lastResult,
    );
  }
}
