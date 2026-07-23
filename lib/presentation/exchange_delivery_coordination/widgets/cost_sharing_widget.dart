import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class CostSharingWidget extends StatelessWidget {
  final int totalCost;
  final int myCost;
  final double distanceKm;

  const CostSharingWidget({
    super.key,
    required this.totalCost,
    required this.myCost,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Partage des frais',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 12.8),
          _buildRow('Distance', '${distanceKm.toStringAsFixed(1)} km'),
          _buildRow('Frais de base', '1 000 FCFA'),
          _buildRow(
            'Frais kilométriques',
            '${(distanceKm * 500).round()} FCFA',
          ),
          const Divider(height: 20),
          _buildRow(
            'Total livraison',
            '$totalCost FCFA',
            isBold: true,
            color: AppTheme.textPrimary,
          ),
          _buildRow(
            'Votre part (50%)',
            '$myCost FCFA',
            isBold: true,
            color: AppTheme.primaryGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
              color: color ?? AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
