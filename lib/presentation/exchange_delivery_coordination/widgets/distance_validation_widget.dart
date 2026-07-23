import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class DistanceValidationWidget extends StatelessWidget {
  final double distanceKm;
  final bool isValid;

  const DistanceValidationWidget({
    super.key,
    required this.distanceKm,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    if (!isValid) {
      return Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppTheme.errorRed.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: AppTheme.errorRed.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            const Icon(Icons.location_off, color: AppTheme.errorRed, size: 40),
            SizedBox(height: 8.5),
            Text(
              'Distance trop grande',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.errorRed,
              ),
            ),
            SizedBox(height: 4.3),
            Text(
              'Les utilisateurs sont à ${distanceKm.toStringAsFixed(1)} km l\'un de l\'autre.\nL\'échange avec livreur est limité à 10 km.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.8),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppTheme.successGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppTheme.successGreen,
            size: 20,
          ),
          SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'Distance : ${distanceKm.toStringAsFixed(1)} km — Échange possible',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.successGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
