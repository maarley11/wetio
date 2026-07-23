import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CommissionBreakdownWidget extends StatelessWidget {
  final double deliveryFee;
  final double commissionRate;
  final double platformCommission;
  final double partnerPayout;

  const CommissionBreakdownWidget({
    super.key,
    required this.deliveryFee,
    required this.commissionRate,
    required this.platformCommission,
    required this.partnerPayout,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.primaryGreen, size: 18),
              SizedBox(width: 8.0),
              Text(
                'Répartition transparente',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.8),
          _buildRow(
            context,
            'Frais de livraison total',
            '${deliveryFee.toStringAsFixed(0)} FCFA',
            colorScheme.onSurface,
            isBold: true,
          ),
          _buildRow(
            context,
            'Commission WETIO (${(commissionRate * 100).toStringAsFixed(0)}%)',
            '- ${platformCommission.toStringAsFixed(0)} FCFA',
            AppTheme.primaryOrange,
          ),
          Divider(height: 17.0),
          _buildRow(
            context,
            'Revenu livreur',
            '${partnerPayout.toStringAsFixed(0)} FCFA',
            AppTheme.primaryGreen,
            isBold: true,
          ),
          SizedBox(height: 8.5),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: (partnerPayout / deliveryFee * 100).round(),
                  child: Container(height: 8, color: AppTheme.primaryGreen),
                ),
                Expanded(
                  flex: (platformCommission / deliveryFee * 100).round(),
                  child: Container(height: 8, color: AppTheme.primaryOrange),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    color: AppTheme.primaryGreen,
                  ),
                  SizedBox(width: 4.0),
                  Text(
                    'Livreur ${(partnerPayout / deliveryFee * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    color: AppTheme.primaryOrange,
                  ),
                  SizedBox(width: 4.0),
                  Text(
                    'WETIO ${(platformCommission / deliveryFee * 100).toStringAsFixed(0)}%',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
