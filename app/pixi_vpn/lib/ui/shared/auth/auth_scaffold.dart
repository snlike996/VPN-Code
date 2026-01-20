import 'package:flutter/material.dart';

class AuthLayout {
  final double spacing;
  final double fieldHeight;
  final double buttonHeight;
  final bool useScroll;

  const AuthLayout({
    required this.spacing,
    required this.fieldHeight,
    required this.buttonHeight,
    required this.useScroll,
  });
}

class AuthScaffold extends StatelessWidget {
  final Widget Function(BuildContext context, AuthLayout layout) builder;
  final VoidCallback? onBack;
  final VoidCallback? onExit;
  final bool showBack;
  final bool showExit;

  const AuthScaffold({
    super.key,
    required this.builder,
    this.onBack,
    this.onExit,
    this.showBack = false,
    this.showExit = false,
  });

  AuthLayout _layoutFor(double height) {
    if (height >= 900) {
      return const AuthLayout(
        spacing: 24,
        fieldHeight: 52,
        buttonHeight: 56,
        useScroll: false,
      );
    }
    if (height >= 700) {
      return const AuthLayout(
        spacing: 18,
        fieldHeight: 48,
        buttonHeight: 52,
        useScroll: false,
      );
    }
    return const AuthLayout(
      spacing: 12,
      fieldHeight: 44,
      buttonHeight: 48,
      useScroll: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _layoutFor(constraints.maxHeight);
        final content = Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: builder(context, layout),
            ),
          ),
        );

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: (showBack || showExit) ? kToolbarHeight : 1,
            leading: showBack
                ? IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                  )
                : null,
            actions: showExit
                ? [
                    IconButton(
                      onPressed: onExit,
                      icon: const Icon(Icons.close),
                    ),
                  ]
                : null,
          ),
          body: SafeArea(
            child: layout.useScroll && constraints.maxHeight < 560
                ? SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: content,
                  )
                : content,
          ),
        );
      },
    );
  }
}
