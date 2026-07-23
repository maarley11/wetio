import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

class PaymentSummaryWidget extends StatelessWidget {
  final int tokenAmount;
  final int price;
  final int currentBalance;

  const PaymentSummaryWidget({
    Key? key,
    required this.tokenAmount,
    required this.price,
    this.currentBalance = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'receipt',
                color: colorScheme.primary,
                size: 24.0,
              ),
              SizedBox(width: 12.0),
              Text(
                'Résumé de l\'achat',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.0),

          // Current balance
          _buildSummaryRow(
            'Solde actuel',
            '$currentBalance jetons',
            isHighlighted: false,
            colorScheme: colorScheme,
          ),

          Divider(height: 24.0, color: Colors.grey[200]),

          // Purchase details
          _buildSummaryRow(
            'Jetons à acheter',
            '$tokenAmount jetons',
            isHighlighted: true,
            colorScheme: colorScheme,
          ),

          _buildSummaryRow(
            'Prix',
            '$price FCFA',
            isHighlighted: false,
            colorScheme: colorScheme,
          ),

          Divider(height: 24.0, color: Colors.grey[200]),

          // New balance after purchase
          _buildSummaryRow(
            'Nouveau solde',
            '${currentBalance + tokenAmount} jetons',
            isHighlighted: true,
            colorScheme: colorScheme,
            isTotal: true,
          ),

          SizedBox(height: 12.0),

          // Benefits reminder
          Container(
            padding: EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'info',
                  color: colorScheme.primary,
                  size: 16.0,
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Avec $tokenAmount jetons, vous pourrez publier ${(tokenAmount / 10).floor()} produits',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    required bool isHighlighted,
    required ColorScheme colorScheme,
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
              color: isTotal
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isTotal ? 16 : 14,
              fontWeight:
                  isHighlighted || isTotal ? FontWeight.w600 : FontWeight.w400,
              color: isHighlighted || isTotal
                  ? colorScheme.primary
                  : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
