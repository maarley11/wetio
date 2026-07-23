import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class DistanceCheckWidget extends StatelessWidget {
  final double distanceKm;
  final bool isValid;

  const DistanceCheckWidget({
    super.key,
    required this.distanceKm,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isValid
            ? AppTheme.successGreen.withValues(alpha: 0.08)
            : AppTheme.errorRed.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isValid
              ? AppTheme.successGreen.withValues(alpha: 0.3)
              : AppTheme.errorRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isValid
                  ? AppTheme.successGreen.withValues(alpha: 0.15)
                  : AppTheme.errorRed.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isValid
                  ? Icons.check_circle_outline
                  : Icons.warning_amber_rounded,
              color: isValid ? AppTheme.successGreen : AppTheme.errorRed,
              size: 24,
            ),
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isValid ? 'Distance compatible' : 'Distance trop grande',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isValid ? AppTheme.successGreen : AppTheme.errorRed,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isValid
                      ? 'Distance : ${distanceKm.toStringAsFixed(1)} km (limite : 10 km)'
                      : 'Les utilisateurs sont trop éloignés pour un échange avec livreur. Distance : ${distanceKm.toStringAsFixed(1)} km',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: isValid
                        ? AppTheme.successGreen.withValues(alpha: 0.8)
                        : AppTheme.errorRed.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
