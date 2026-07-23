import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class ExchangeSummaryWidget extends StatelessWidget {
  final String personAName;
  final String personBName;
  final String personAProduct;
  final String personBProduct;
  final String personAAddress;
  final String personBAddress;

  const ExchangeSummaryWidget({
    super.key,
    required this.personAName,
    required this.personBName,
    required this.personAProduct,
    required this.personBProduct,
    required this.personAAddress,
    required this.personBAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Résumé de l\'échange',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 17.0),
          _buildPersonRow(
            icon: Icons.person,
            color: AppTheme.primaryGreen,
            name: personAName,
            product: personAProduct,
            address: personAAddress,
            label: 'Personne A',
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.5),
            child: Row(
              children: [
                SizedBox(width: 20.0),
                Container(width: 2, height: 25.5, color: AppTheme.borderLight),
                SizedBox(width: 12.0),
                const Icon(
                  Icons.swap_vert,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
                SizedBox(width: 8.0),
                Text(
                  'Échange bidirectionnel',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          _buildPersonRow(
            icon: Icons.person_outline,
            color: Colors.orange,
            name: personBName,
            product: personBProduct,
            address: personBAddress,
            label: 'Personne B',
          ),
        ],
      ),
    );
  }

  Widget _buildPersonRow({
    required IconData icon,
    required Color color,
    required String name,
    required String product,
    required String address,
    required String label,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
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
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.inventory_2_outlined,
                    size: 13,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      product,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (address.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}
