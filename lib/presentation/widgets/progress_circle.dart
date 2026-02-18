import 'package:flutter/material.dart';

class ProgressCircle extends StatelessWidget {
  final double progress;
  final double size;
  final String? label;

  const ProgressCircle({
    super.key,
    required this.progress,
    this.size = 80,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value =
        progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0).toDouble();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 7,
              backgroundColor:
                  theme.colorScheme.primary.withOpacity(0.08),
            ),
          ),
          if (label != null)
            Text(
              label!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

