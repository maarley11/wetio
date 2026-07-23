import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class CoverageAreaWidget extends StatelessWidget {
  final String selectedRegion;
  final int availablePartners;
  final double radius;

  const CoverageAreaWidget({
    super.key,
    required this.selectedRegion,
    required this.availablePartners,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final coverageQuality = _getCoverageQuality();
    final estimatedCoverage = _calculateCoveragePercentage();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.radar,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Zone de couverture',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCoverageColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  coverageQuality,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getCoverageColor(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Coverage visualization
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$selectedRegion - Rayon ${radius.round()} km',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Progress bar for coverage
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.borderLight.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: estimatedCoverage / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getCoverageColor(),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      'Couverture estimée: ${estimatedCoverage.round()}%',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Coverage stats
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    Text(
                      availablePartners.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    Text(
                      'Livreurs',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Service boundaries info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.borderLight.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Informations sur la zone',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildServiceBoundaryInfo(),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Quick actions for coverage
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                  'Élargir zone',
                  Icons.zoom_out_map,
                  () => _expandCoverage(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickAction(
                  'Zones voisines',
                  Icons.explore,
                  () => _showNeighboringZones(context),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickAction(
                  'Temps optimal',
                  Icons.schedule,
                  () => _showOptimalTimes(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getCoverageQuality() {
    if (availablePartners >= 5) return 'Excellente';
    if (availablePartners >= 3) return 'Bonne';
    if (availablePartners >= 1) return 'Limitée';
    return 'Aucune';
  }

  Color _getCoverageColor() {
    if (availablePartners >= 5) return AppTheme.successGreen;
    if (availablePartners >= 3) return AppTheme.primaryGreen;
    if (availablePartners >= 1) return AppTheme.warningOrange;
    return AppTheme.errorRed;
  }

  double _calculateCoveragePercentage() {
    // Simplified calculation based on partners and region
    double basePercentage = (availablePartners * 15.0).clamp(0.0, 85.0);

    // Adjust for region characteristics
    switch (selectedRegion) {
      case 'Dakar':
        basePercentage += 10;
        break;
      case 'Thiès':
        basePercentage += 5;
        break;
      case 'Saint-Louis':
        basePercentage += 3;
        break;
      default:
        basePercentage += 0;
    }

    // Adjust for radius (smaller radius = better coverage)
    if (radius <= 10) basePercentage += 5;
    if (radius >= 30) basePercentage -= 10;

    return basePercentage.clamp(0.0, 100.0);
  }

  Widget _buildServiceBoundaryInfo() {
    switch (selectedRegion) {
      case 'Dakar':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('• Service 24h/24 dans le centre-ville'),
            _buildInfoItem('• Couverture optimale jusqu\'à 15km'),
            _buildInfoItem('• Zones premium: Plateau, Almadies, Point E'),
          ],
        );
      case 'Thiès':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('• Service standard 6h-22h'),
            _buildInfoItem('• Spécialisé transport commercial'),
            _buildInfoItem('• Liaison rapide avec Dakar disponible'),
          ],
        );
      case 'Saint-Louis':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('• Service touristique prioritaire'),
            _buildInfoItem('• Couverture île et continent'),
            _buildInfoItem('• Horaires adaptés saison touristique'),
          ],
        );
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoItem('• Service de base disponible'),
            _buildInfoItem('• Horaires variables selon demande'),
            _buildInfoItem('• Possibilité livraison inter-régionale'),
          ],
        );
    }
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border:
              Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _expandCoverage(BuildContext context) {
    // Handle expand coverage action
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Zone élargie à 25km automatiquement'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  void _showNeighboringZones(BuildContext context) {
    final neighboringRegions = _getNeighboringRegions();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Zones voisines',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: neighboringRegions
              .map((region) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('• $region'),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showOptimalTimes(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Créneaux optimaux',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pour $selectedRegion:',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            const Text('• Matin: 8h-11h (optimal)'),
            const Text('• Midi: 12h-14h (moyen)'),
            const Text('• Après-midi: 16h-19h (optimal)'),
            const Text('• Soir: 20h-22h (limité)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  List<String> _getNeighboringRegions() {
    switch (selectedRegion) {
      case 'Dakar':
        return ['Thiès', 'Rufisque', 'Bargny'];
      case 'Thiès':
        return ['Dakar', 'Diourbel', 'Louga'];
      case 'Saint-Louis':
        return ['Louga', 'Matam', 'Podor'];
      case 'Kaolack':
        return ['Fatick', 'Kaffrine', 'Diourbel'];
      default:
        return ['Régions adjacentes disponibles'];
    }
  }
}
