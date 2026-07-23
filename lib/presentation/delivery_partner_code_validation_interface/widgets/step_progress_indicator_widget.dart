import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class StepProgressIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final String personAName;
  final String personBName;

  const StepProgressIndicatorWidget({
    super.key,
    required this.currentStep,
    required this.personAName,
    required this.personBName,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      _StepInfo(
        label: 'Chez $personAName',
        icon: Icons.home_outlined,
        color: AppTheme.primaryGreen,
      ),
      _StepInfo(
        label: 'Chez $personBName',
        icon: Icons.swap_horiz,
        color: Colors.orange,
      ),
      _StepInfo(
        label: 'Retour $personAName',
        icon: Icons.check_circle_outline,
        color: Colors.blue,
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progression de la livraison',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 12.8),
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final stepIndex = i ~/ 2;
                final isCompleted = currentStep > stepIndex;
                return Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.successGreen
                          : AppTheme.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }
              final stepIndex = i ~/ 2;
              final isCompleted = currentStep > stepIndex;
              final isActive = currentStep == stepIndex;
              final step = steps[stepIndex];
              return Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.successGreen
                          : isActive
                              ? step.color
                              : AppTheme.borderLight,
                      shape: BoxShape.circle,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: step.color.withValues(alpha: 0.35),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : step.icon,
                      color: isCompleted || isActive
                          ? Colors.white
                          : AppTheme.textSecondary,
                      size: 18,
                    ),
                  ),
                  SizedBox(height: 4.3),
                  SizedBox(
                    width: 88.0,
                    child: Text(
                      step.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isCompleted
                            ? AppTheme.successGreen
                            : isActive
                                ? step.color
                                : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _StepInfo {
  final String label;
  final IconData icon;
  final Color color;
  const _StepInfo({
    required this.label,
    required this.icon,
    required this.color,
  });
}
