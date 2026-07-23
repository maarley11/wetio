import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class RegionSelectorWidget extends StatelessWidget {
  final String selectedRegion;
  final String selectedNeighborhood;
  final List<String> regions;
  final List<String> neighborhoods;
  final Function(String) onRegionChanged;
  final Function(String) onNeighborhoodChanged;

  const RegionSelectorWidget({
    super.key,
    required this.selectedRegion,
    required this.selectedNeighborhood,
    required this.regions,
    required this.neighborhoods,
    required this.onRegionChanged,
    required this.onNeighborhoodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionner une région',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // Region dropdown
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.borderLight),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedRegion,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.textSecondary,
                ),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
                items: regions.map((region) {
                  return DropdownMenuItem<String>(
                    value: region,
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_city,
                          size: 18,
                          color: region == selectedRegion
                              ? AppTheme.primaryGreen
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          region,
                          style: GoogleFonts.inter(
                            fontWeight: region == selectedRegion
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onRegionChanged(value);
                  }
                },
              ),
            ),
          ),

          if (neighborhoods.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Quartier (optionnel)',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),

            // Neighborhood chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // "All" chip
                GestureDetector(
                  onTap: () => onNeighborhoodChanged(''),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selectedNeighborhood.isEmpty
                          ? AppTheme.primaryGreen
                          : AppTheme.borderLight.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedNeighborhood.isEmpty
                            ? AppTheme.primaryGreen
                            : AppTheme.borderLight,
                      ),
                    ),
                    child: Text(
                      'Tous les quartiers',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: selectedNeighborhood.isEmpty
                            ? AppTheme.surfaceWhite
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),

                // Neighborhood chips
                ...neighborhoods.map((neighborhood) {
                  final isSelected = selectedNeighborhood == neighborhood;

                  return GestureDetector(
                    onTap: () =>
                        onNeighborhoodChanged(isSelected ? '' : neighborhood),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.borderLight,
                        ),
                      ),
                      child: Text(
                        neighborhood,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? AppTheme.surfaceWhite
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // Quick region stats
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getRegionInfo(selectedRegion),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.primaryGreen,
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

  String _getRegionInfo(String region) {
    switch (region) {
      case 'Dakar':
        return 'Capitale - Zone à forte densité de livreurs disponibles 24h/24';
      case 'Thiès':
        return 'Centre industriel - Bonne couverture, spécialisée en transport commercial';
      case 'Saint-Louis':
        return 'Ville historique - Service standard, idéal pour livraisons touristiques';
      case 'Kaolack':
        return 'Hub commercial - Excellente pour transport de marchandises';
      default:
        return 'Zone en développement - Service de base disponible';
    }
  }
}
