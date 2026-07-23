import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CommissionStructureWidget extends StatelessWidget {
  const CommissionStructureWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Structure des commissions',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.5),
        Text(
          'La commission varie entre 15% et 25% selon plusieurs facteurs.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        SizedBox(height: 17.0),
        // Commission tiers
        _buildCommissionTier(
          context,
          rate: '15%',
          label: 'Longue distance (>10 km)',
          description: 'Livraisons de plus de 10 km pour maximiser vos gains',
          color: AppTheme.successGreen,
          icon: Icons.directions_bike,
        ),
        SizedBox(height: 12.8),
        _buildCommissionTier(
          context,
          rate: '17%',
          label: 'Distance moyenne (5-10 km)',
          description: 'Livraisons entre 5 et 10 km',
          color: AppTheme.primaryGreen,
          icon: Icons.route,
        ),
        SizedBox(height: 12.8),
        _buildCommissionTier(
          context,
          rate: '20%',
          label: 'Distance courte (2-5 km)',
          description: 'Livraisons entre 2 et 5 km',
          color: AppTheme.primaryOrange,
          icon: Icons.near_me,
        ),
        SizedBox(height: 12.8),
        _buildCommissionTier(
          context,
          rate: '25%',
          label: 'Très courte (<2 km)',
          description: 'Livraisons de moins de 2 km',
          color: AppTheme.errorRed,
          icon: Icons.location_on,
        ),
        SizedBox(height: 25.5),
        // Example calculation
        Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calculate, color: AppTheme.primaryGreen, size: 20),
                  SizedBox(width: 8.0),
                  Text(
                    'Exemple de calcul',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 17.0),
              _buildCalculationRow(
                'Client paie',
                '1 000 FCFA',
                colorScheme.onSurface,
                colorScheme,
              ),
              _buildCalculationRow(
                'Commission plateforme (20%)',
                '-200 FCFA',
                AppTheme.errorRed,
                colorScheme,
              ),
              Divider(color: colorScheme.outline.withValues(alpha: 0.3)),
              _buildCalculationRow(
                'Vous recevez',
                '800 FCFA',
                AppTheme.primaryGreen,
                colorScheme,
                isBold: true,
              ),
              SizedBox(height: 8.5),
              Text(
                '+ Pourboire éventuel du client (non soumis à commission)',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppTheme.primaryOrange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 25.5),
        // Tier benefits
        Text(
          'Avantages par niveau',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 17.0),
        _buildTierBenefitCard(
          context,
          tier: 'Bronze',
          deliveries: '0-50 livraisons',
          commission: '20-25%',
          color: Colors.brown[400]!,
        ),
        SizedBox(height: 12.8),
        _buildTierBenefitCard(
          context,
          tier: 'Silver',
          deliveries: '51-200 livraisons',
          commission: '17-20%',
          color: Colors.grey[500]!,
        ),
        SizedBox(height: 12.8),
        _buildTierBenefitCard(
          context,
          tier: 'Gold',
          deliveries: '201-500 livraisons',
          commission: '15-17%',
          color: Colors.amber[600]!,
        ),
        SizedBox(height: 12.8),
        _buildTierBenefitCard(
          context,
          tier: 'Platinum',
          deliveries: '500+ livraisons',
          commission: '15%',
          color: Colors.blueGrey[400]!,
        ),
      ],
    );
  }

  Widget _buildCommissionTier(
    BuildContext context, {
    required String rate,
    required String label,
    required String description,
    required Color color,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            rate,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationRow(
    String label,
    String value,
    Color valueColor,
    ColorScheme colorScheme, {
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierBenefitCard(
    BuildContext context, {
    required String tier,
    required String deliveries,
    required String commission,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.military_tech, color: color, size: 28),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tier,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  deliveries,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              commission,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
