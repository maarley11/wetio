import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PartnerEarningsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> partnerStats;
  final double totalPayouts;
  final double pendingPayouts;

  const PartnerEarningsWidget({
    super.key,
    required this.partnerStats,
    required this.totalPayouts,
    required this.pendingPayouts,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'Total versé',
                  '${_formatAmount(totalPayouts)} FCFA',
                  Icons.payments_outlined,
                  AppTheme.primaryGreen,
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: _buildSummaryCard(
                  context,
                  'En attente',
                  '${_formatAmount(pendingPayouts)} FCFA',
                  Icons.pending_outlined,
                  AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
          SizedBox(height: 17.0),
          Container(
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: AppTheme.primaryGreen, size: 18),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Règlement automatique chaque lundi. Prochain versement: Lundi 10 Mars',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 17.0),
          Text(
            'Statistiques par livreur',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.8),
          ...partnerStats.map((partner) => _buildPartnerCard(context, partner)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(12.0),
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
          Icon(icon, color: color, size: 20),
          SizedBox(height: 8.5),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerCard(BuildContext context, Map<String, dynamic> partner) {
    final colorScheme = Theme.of(context).colorScheme;
    final tier = partner['tier'] as String;
    final status = partner['status'] as String;

    Color tierColor;
    switch (tier) {
      case 'Gold':
        tierColor = const Color(0xFFFFD700);
        break;
      case 'Silver':
        tierColor = Colors.grey;
        break;
      default:
        tierColor = const Color(0xFFCD7F32);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.8),
      padding: EdgeInsets.all(12.0),
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
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                child: Text(
                  (partner['name'] as String)[0],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          partner['name'] as String,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(width: 8.0),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: tierColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tier,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: tierColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${partner['deliveries']} livraisons • Commission: ${partner['commission']}%',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_formatAmount((partner['earnings'] as num).toDouble())} FCFA',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'active'
                          ? AppTheme.successGreen.withValues(alpha: 0.1)
                          : AppTheme.warningOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status == 'active' ? 'Actif' : 'En attente',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        color: status == 'active'
                            ? AppTheme.successGreen
                            : AppTheme.warningOrange,
                      ),
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

  String _formatAmount(double amount) {
    if (amount >= 1_000_000) {
      return '${(amount / 1_000_000).toStringAsFixed(1)}M';
    } else if (amount >= 1_000) {
      return '${(amount / 1_000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }
}
