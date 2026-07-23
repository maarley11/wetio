import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class CommissionStructureWidget extends StatefulWidget {
  final double avgRate;

  const CommissionStructureWidget({super.key, required this.avgRate});

  @override
  State<CommissionStructureWidget> createState() =>
      _CommissionStructureWidgetState();
}

class _CommissionStructureWidgetState extends State<CommissionStructureWidget> {
  double _previewDeliveryFee = 1000;
  double _previewRate = 20;

  double get _platformShare => _previewDeliveryFee * (_previewRate / 100);
  double get _partnerShare => _previewDeliveryFee - _platformShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Structure des commissions',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12.8),
          _buildRuleCard(
            context,
            'Distance courte (< 5 km)',
            '25%',
            'Zone urbaine dense',
            Icons.location_city,
            AppTheme.primaryOrange,
          ),
          _buildRuleCard(
            context,
            'Distance moyenne (5-15 km)',
            '22%',
            'Périphérie urbaine',
            Icons.directions_car,
            AppTheme.primaryGreen,
          ),
          _buildRuleCard(
            context,
            'Distance longue (15-30 km)',
            '18%',
            'Zone suburbaine',
            Icons.route,
            Colors.blue,
          ),
          _buildRuleCard(
            context,
            'Très longue distance (> 30 km)',
            '15%',
            'Zone rurale / interurbaine',
            Icons.landscape,
            Colors.purple,
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
                  'Simulateur de commission',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 17.0),
                Text(
                  'Frais de livraison: ${_previewDeliveryFee.toStringAsFixed(0)} FCFA',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Slider(
                  value: _previewDeliveryFee,
                  min: 500,
                  max: 10000,
                  divisions: 19,
                  activeColor: AppTheme.primaryGreen,
                  onChanged: (val) => setState(() => _previewDeliveryFee = val),
                ),
                Text(
                  'Taux de commission: ${_previewRate.toStringAsFixed(0)}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Slider(
                  value: _previewRate,
                  min: 15,
                  max: 25,
                  divisions: 10,
                  activeColor: AppTheme.primaryOrange,
                  onChanged: (val) => setState(() => _previewRate = val),
                ),
                SizedBox(height: 8.5),
                Row(
                  children: [
                    Expanded(
                      child: _buildPreviewBox(
                        context,
                        'Part plateforme',
                        '${_platformShare.toStringAsFixed(0)} FCFA',
                        AppTheme.primaryOrange,
                      ),
                    ),
                    SizedBox(width: 12.0),
                    Expanded(
                      child: _buildPreviewBox(
                        context,
                        'Part livreur',
                        '${_partnerShare.toStringAsFixed(0)} FCFA',
                        AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(
    BuildContext context,
    String title,
    String rate,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
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
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              rate,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewBox(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
