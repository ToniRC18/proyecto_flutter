import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class OnboardingProgressDots extends StatelessWidget {
  final int active;
  final int total;

  const OnboardingProgressDots({
    super.key,
    required this.active,
    this.total = 6,
  });

  @override
  Widget build(BuildContext context) {
    final b = context.bruma;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isActive = index == active;
        return Padding(
          padding: EdgeInsets.only(right: index == total - 1 ? 0 : 6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: isActive ? 24 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? b.primary : b.border,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
