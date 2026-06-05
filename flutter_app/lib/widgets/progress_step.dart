import 'package:flutter/material.dart';
import '../app.dart';

/// Matrix-themed progress step.
///
/// Based on openclaw-termux (https://github.com/mithun50/openclaw-termux)
/// — MIT License.
class ProgressStep extends StatelessWidget {
  final int stepNumber;
  final String label;
  final bool isActive;
  final bool isComplete;
  final bool hasError;
  final double? progress;

  const ProgressStep({
    super.key,
    required this.stepNumber,
    required this.label,
    this.isActive = false,
    this.isComplete = false,
    this.hasError = false,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    Color indicatorColor;
    String indicator;

    if (hasError) {
      indicatorColor = AppColors.statusRed;
      indicator = '!';
    } else if (isComplete) {
      indicatorColor = AppColors.matrixGreen;
      indicator = '✓';
    } else if (isActive) {
      indicatorColor = AppColors.matrixGreen;
      indicator = '>';
    } else {
      indicatorColor = AppColors.statusGrey;
      indicator = '$stepNumber';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              border: Border.all(color: indicatorColor),
            ),
            alignment: Alignment.center,
            child: Text(
              indicator,
              style: TextStyle(
                color: indicatorColor,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive || isComplete
                        ? AppColors.matrixGreen
                        : AppColors.mutedText,
                    fontSize: 13,
                    letterSpacing: 0.5,
                  ),
                ),
                if (isActive && progress != null) ...[
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress! > 0.0 ? progress : null,
                      backgroundColor: AppColors.border,
                      color: AppColors.matrixGreen,
                      minHeight: 4,
                    ),
                  ),
                  if (progress! > 0.0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '${(progress! * 100).toInt()}%',
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
