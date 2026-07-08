import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double progress;
  final double height;
  final Color? backgroundColor;
  final Color? progressColor;
  final String? label;
  final bool showPercentage;

  const ProgressBar({
    super.key,
    required this.progress,
    this.height = 8,
    this.backgroundColor,
    this.progressColor,
    this.label,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (showPercentage)
                  Text(
                    '${(clampedProgress * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: clampedProgress,
            backgroundColor: backgroundColor ?? Colors.grey.shade200,
            color: progressColor ?? Theme.of(context).primaryColor,
            minHeight: height,
          ),
        ),
      ],
    );
  }
}