import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class RevenueAnalyticsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyData;
  final double totalCommissions;
  final int totalDeliveries;
  final double avgRate;

  const RevenueAnalyticsWidget({
    super.key,
    required this.weeklyData,
    required this.totalCommissions,
    required this.totalDeliveries,
    required this.avgRate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final maxAmount = weeklyData
        .map((d) => (d['amount'] as int).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Total Commissions',
                  '${_formatAmount(totalCommissions)} FCFA',
                  Icons.account_balance_wallet,
                  AppTheme.primaryGreen,
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: _buildMetricCard(
                  context,
                  'Livraisons',
                  '$totalDeliveries',
                  Icons.delivery_dining,
                  AppTheme.primaryOrange,
                ),
              ),
            ],
          ),
          SizedBox(height: 17.0),
          Container(
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
                Text(
                  'Revenus hebdomadaires',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 17.0),
                SizedBox(
                  height: 170.0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: weeklyData.map((data) {
                      final amount = (data['amount'] as int).toDouble();
                      final barHeight = (amount / maxAmount) * 153.0;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _formatAmount(amount),
                            style: GoogleFonts.inter(
                              fontSize: 8,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 4.3),
                          Container(
                            width: 32.0,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          SizedBox(height: 4.3),
                          Text(
                            data['day'] as String,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 17.0),
          Container(
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
                Text(
                  'Taux de commission par distance',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 12.8),
                _buildRateRow(context, '< 5 km', '25%', 1.0),
                _buildRateRow(context, '5 - 15 km', '22%', 0.88),
                _buildRateRow(context, '15 - 30 km', '18%', 0.72),
                _buildRateRow(context, '> 30 km', '15%', 0.6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
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
          Icon(icon, color: color, size: 22),
          SizedBox(height: 8.5),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
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

  Widget _buildRateRow(
    BuildContext context,
    String distance,
    String rate,
    double progress,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 12.8),
      child: Row(
        children: [
          SizedBox(
            width: 80.0,
            child: Text(
              distance,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryOrange,
                ),
                minHeight: 8,
              ),
            ),
          ),
          SizedBox(width: 8.0),
          Text(
            rate,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryOrange,
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
