import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PerformanceMetricsWidget extends StatelessWidget {
  final Map<String, dynamic> weeklyData;

  const PerformanceMetricsWidget({super.key, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final completionRate = weeklyData['completionRate'] as double;
    final avgRating = weeklyData['avgRating'] as double;
    final commissionRate = weeklyData['commissionRate'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performances',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 17.0),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.check_circle_outline,
                label: 'Taux de complétion',
                value: '$completionRate%',
                color: AppTheme.successGreen,
                subtitle: 'Excellent',
              ),
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.star_outline,
                label: 'Note moyenne',
                value: '$avgRating/5',
                color: Colors.amber[600]!,
                subtitle: 'Très bien',
              ),
            ),
            SizedBox(width: 12.0),
            Expanded(
              child: _buildMetricCard(
                context,
                icon: Icons.percent,
                label: 'Commission actuelle',
                value: '$commissionRate%',
                color: AppTheme.primaryGreen,
                subtitle: 'Niveau Silver',
              ),
            ),
          ],
        ),
        SizedBox(height: 17.0),
        // Optimization tip
        Container(
          padding: EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: AppTheme.primaryOrange.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppTheme.primaryOrange,
                size: 20,
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Conseil: Privilégiez les livraisons longue distance (>10 km) pour réduire votre commission à 15% et maximiser vos gains.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required String subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8.5),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.3),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
