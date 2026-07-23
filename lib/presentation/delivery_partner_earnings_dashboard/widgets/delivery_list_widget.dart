import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class DeliveryListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> deliveries;

  const DeliveryListWidget({super.key, required this.deliveries});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Livraisons complétées',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 17.0),
        ...deliveries.map(
          (delivery) => _buildDeliveryCard(delivery, colorScheme, context),
        ),
      ],
    );
  }

  Widget _buildDeliveryCard(
    Map<String, dynamic> delivery,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    final baseAmount = delivery['baseAmount'] as int;
    final commission = delivery['commission'] as int;
    final tip = delivery['tip'] as int;
    final netEarning = delivery['netEarning'] as int;
    final commissionRate = delivery['commissionRate'] as int;

    return Container(
      margin: EdgeInsets.only(bottom: 17.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery['client'],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${delivery['date']} à ${delivery['time']}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '+$netEarning FCFA',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.8),
          Row(
            children: [
              Icon(Icons.route, size: 14, color: colorScheme.onSurfaceVariant),
              SizedBox(width: 4.0),
              Expanded(
                child: Text(
                  '${delivery['from']} → ${delivery['to']}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                delivery['distance'],
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.8),
          Container(
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAmountItem(
                  'Brut',
                  '$baseAmount F',
                  colorScheme.onSurface,
                ),
                Text(
                  '-',
                  style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
                ),
                _buildAmountItem(
                  'Commission ($commissionRate%)',
                  '-$commission F',
                  AppTheme.errorRed,
                ),
                Text(
                  '+',
                  style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
                ),
                _buildAmountItem(
                  'Pourboire',
                  '+$tip F',
                  AppTheme.primaryOrange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
