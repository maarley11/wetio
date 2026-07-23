import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CommissionHeaderWidget extends StatelessWidget {
  final double totalRevenue;
  final bool isWeeklyView;
  final double avgCommissionRate;
  final Function(bool) onToggle;

  const CommissionHeaderWidget({
    super.key,
    required this.totalRevenue,
    required this.isWeeklyView,
    required this.avgCommissionRate,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isWeeklyView ? 'Revenus cette semaine' : 'Revenus ce mois',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  SizedBox(height: 4.3),
                  Text(
                    '${_formatAmount(totalRevenue)} FCFA',
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _buildToggleBtn(
                      'Semaine',
                      isWeeklyView,
                      () => onToggle(true),
                    ),
                    _buildToggleBtn(
                      'Mois',
                      !isWeeklyView,
                      () => onToggle(false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.8),
          Row(
            children: [
              _buildStatChip(
                'Commission moy.',
                '${avgCommissionRate.toStringAsFixed(1)}%',
                Icons.percent,
              ),
              SizedBox(width: 12.0),
              _buildStatChip('Fourchette', '15-25%', Icons.tune),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? AppTheme.primaryGreen : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          SizedBox(width: 4.0),
          Text(
            '$label: $value',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1_000_000) {
      return '${(amount / 1_000_000).toStringAsFixed(1)}M';
    } else if (amount >= 1_000) {
      return '${(amount / 1_000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
