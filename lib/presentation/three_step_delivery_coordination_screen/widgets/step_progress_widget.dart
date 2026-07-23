import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class StepProgressWidget extends StatelessWidget {
  final int currentStep;

  const StepProgressWidget({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = [
      {'label': 'Collecte', 'icon': Icons.directions_bike_outlined},
      {'label': 'Échange', 'icon': Icons.swap_horiz},
      {'label': 'Livraison', 'icon': Icons.home_outlined},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                final stepIndex = index ~/ 2;
                final isCompleted = currentStep > stepIndex;
                return Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.primaryGreen
                          : AppTheme.borderLight,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                );
              }
              final stepIndex = index ~/ 2;
              final isCompleted = currentStep > stepIndex;
              final isActive = currentStep == stepIndex;
              final step = steps[stepIndex];
              return Column(
                children: [
                  Container(
                    width: 48.0,
                    height: 48.0,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.primaryGreen
                          : isActive
                              ? AppTheme.primaryGreen.withValues(alpha: 0.15)
                              : AppTheme.borderLight.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: isActive
                          ? Border.all(
                              color: AppTheme.primaryGreen,
                              width: 2,
                            )
                          : null,
                    ),
                    child: isCompleted
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : Icon(
                            step['icon'] as IconData,
                            color: isActive
                                ? AppTheme.primaryGreen
                                : AppTheme.textSecondary,
                            size: 18,
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    step['label'] as String,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: isActive || isCompleted
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: isActive || isCompleted
                          ? AppTheme.primaryGreen
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              );
            }),
          ),
          SizedBox(height: 12.8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStepColor(currentStep).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              _getStepLabel(currentStep),
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _getStepColor(currentStep),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStepColor(int step) {
    switch (step) {
      case 0:
        return AppTheme.primaryGreen;
      case 1:
        return AppTheme.primaryOrange;
      case 2:
        return Colors.blue;
      default:
        return AppTheme.successGreen;
    }
  }

  String _getStepLabel(int step) {
    switch (step) {
      case 0:
        return 'Étape 1 : Livreur se rend chez Fatou';
      case 1:
        return 'Étape 2 : Livreur se rend chez Awa';
      case 2:
        return 'Étape 3 : Livreur retourne chez Fatou';
      default:
        return 'Échange terminé !';
    }
  }
}
