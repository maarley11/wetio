import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class PaymentScheduleWidget extends StatelessWidget {
  final List<Map<String, dynamic>> paymentHistory;

  const PaymentScheduleWidget({super.key, required this.paymentHistory});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calendrier des paiements',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.5),
        Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              _buildScheduleRow(
                icon: Icons.calendar_today,
                label: 'Fréquence',
                value: 'Hebdomadaire (chaque dimanche)',
                colorScheme: colorScheme,
              ),
              Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
              _buildScheduleRow(
                icon: Icons.account_balance,
                label: 'Méthode',
                value: 'Virement bancaire automatique',
                colorScheme: colorScheme,
              ),
              Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
              _buildScheduleRow(
                icon: Icons.lock_clock,
                label: 'Délai',
                value: '24-48h après validation',
                colorScheme: colorScheme,
              ),
              Divider(color: colorScheme.outline.withValues(alpha: 0.2)),
              _buildScheduleRow(
                icon: Icons.credit_card,
                label: 'Compte',
                value: '**** **** **** 4521',
                colorScheme: colorScheme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleRow({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryGreen),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
