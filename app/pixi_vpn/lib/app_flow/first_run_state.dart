enum FirstRunStage {
  welcome,
  authChoice,
  login,
  register,
  onboarding,
  completed,
}

class FirstRunState {
  final FirstRunStage stage;
  final bool completed;

  const FirstRunState({
    required this.stage,
    required this.completed,
  });

  FirstRunState copyWith({
    FirstRunStage? stage,
    bool? completed,
  }) {
    return FirstRunState(
      stage: stage ?? this.stage,
      completed: completed ?? this.completed,
    );
  }
}
