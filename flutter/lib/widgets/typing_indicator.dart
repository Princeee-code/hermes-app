import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 100, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.aiBubble.withAlpha(200),
              AppTheme.surface2.withAlpha(160),
            ],
          ),
          borderRadius: BorderRadius.circular(AppTheme.bubbleRadius),
          border: Border.all(
            color: AppTheme.accentPurple.withAlpha(50),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return _AnimatedDotBuilder(
              listenable: _controller,
              builder: (_, __) {
                final delay = i * 0.15;
                final t = (_controller.value - delay).clamp(0.0, 1.0);
                final size = 6.0 + 5.0 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: const BoxDecoration(
                      gradient: AppTheme.agentGradient,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class _AnimatedDotBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const _AnimatedDotBuilder({
    super.key,
    required super.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context, null);
}
