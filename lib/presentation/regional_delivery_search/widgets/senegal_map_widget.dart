import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../theme/app_theme.dart';

class SenegalMapWidget extends StatefulWidget {
  final String selectedRegion;
  final List<Map<String, dynamic>> deliveryPartners;
  final Function(String) onRegionTap;
  final Position? currentPosition;

  const SenegalMapWidget({
    super.key,
    required this.selectedRegion,
    required this.deliveryPartners,
    required this.onRegionTap,
    this.currentPosition,
  });

  @override
  State<SenegalMapWidget> createState() => _SenegalMapWidgetState();
}

class _SenegalMapWidgetState extends State<SenegalMapWidget> {
  final Map<String, Map<String, dynamic>> _regionData = {
    'Dakar': {
      'position': const Offset(0.2, 0.8),
      'color': AppTheme.primaryGreen,
      'partnerCount': 0,
      'density': 'high',
    },
    'Thiès': {
      'position': const Offset(0.25, 0.75),
      'color': AppTheme.primaryOrange,
      'partnerCount': 0,
      'density': 'medium',
    },
    'Saint-Louis': {
      'position': const Offset(0.15, 0.2),
      'color': AppTheme.successGreen,
      'partnerCount': 0,
      'density': 'low',
    },
    'Kaolack': {
      'position': const Offset(0.4, 0.6),
      'color': AppTheme.warningOrange,
      'partnerCount': 0,
      'density': 'medium',
    },
    'Tambacounda': {
      'position': const Offset(0.8, 0.5),
      'color': AppTheme.textSecondary,
      'partnerCount': 0,
      'density': 'low',
    },
    'Ziguinchor': {
      'position': const Offset(0.3, 0.9),
      'color': AppTheme.primaryGreen,
      'partnerCount': 0,
      'density': 'medium',
    },
  };

  @override
  void initState() {
    super.initState();
    _updatePartnerCounts();
  }

  @override
  void didUpdateWidget(SenegalMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deliveryPartners != widget.deliveryPartners) {
      _updatePartnerCounts();
    }
  }

  void _updatePartnerCounts() {
    // Reset counts
    for (final region in _regionData.keys) {
      _regionData[region]!['partnerCount'] = 0;
    }

    // Count partners by region
    for (final partner in widget.deliveryPartners) {
      final region = partner['region'] as String;
      if (_regionData.containsKey(region)) {
        _regionData[region]!['partnerCount']++;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Background map illustration
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.backgroundWhite,
                    AppTheme.borderLight.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: CustomPaint(
                painter: SenegalMapPainter(),
              ),
            ),

            // Region markers
            ..._regionData.entries.map((entry) {
              final region = entry.key;
              final data = entry.value;
              final position = data['position'] as Offset;
              final partnerCount = data['partnerCount'] as int;
              final isSelected = region == widget.selectedRegion;

              return Positioned(
                left: position.dx * MediaQuery.of(context).size.width - 20,
                top: position.dy * 160 - 20,
                child: GestureDetector(
                  onTap: () => widget.onRegionTap(region),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isSelected ? 50 : 40,
                    height: isSelected ? 50 : 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : _getRegionColor(partnerCount),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.surfaceWhite,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowLight,
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppTheme.surfaceWhite,
                          size: isSelected ? 16 : 12,
                        ),
                        if (partnerCount > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 1),
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceWhite,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              partnerCount.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Region labels
            ..._regionData.entries.map((entry) {
              final region = entry.key;
              final data = entry.value;
              final position = data['position'] as Offset;
              final isSelected = region == widget.selectedRegion;

              return Positioned(
                left: position.dx * MediaQuery.of(context).size.width - 30,
                top: position.dy * 160 + 25,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : AppTheme.surfaceWhite.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : AppTheme.borderLight,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    region,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppTheme.surfaceWhite
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
              );
            }),

            // Legend
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Densité de livreurs',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildLegendItem('Élevée', AppTheme.primaryGreen),
                    _buildLegendItem('Moyenne', AppTheme.warningOrange),
                    _buildLegendItem('Faible', AppTheme.textSecondary),
                  ],
                ),
              ),
            ),

            // Current location indicator
            if (widget.currentPosition != null)
              Positioned(
                left: 20,
                top: 20,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.my_location,
                        color: AppTheme.surfaceWhite,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Votre position',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.surfaceWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRegionColor(int partnerCount) {
    if (partnerCount >= 5) return AppTheme.primaryGreen;
    if (partnerCount >= 2) return AppTheme.warningOrange;
    return AppTheme.textSecondary;
  }
}

class SenegalMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.borderLight.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Simple Senegal outline (simplified)
    final path = Path();

    // Start from northwest
    path.moveTo(size.width * 0.1, size.height * 0.15);
    path.lineTo(size.width * 0.25, size.height * 0.1);
    path.lineTo(size.width * 0.5, size.height * 0.15);
    path.lineTo(size.width * 0.8, size.height * 0.25);
    path.lineTo(size.width * 0.95, size.height * 0.4);
    path.lineTo(size.width * 0.9, size.height * 0.7);
    path.lineTo(size.width * 0.7, size.height * 0.85);
    path.lineTo(size.width * 0.4, size.height * 0.95);
    path.lineTo(size.width * 0.15, size.height * 0.9);
    path.lineTo(size.width * 0.05, size.height * 0.7);
    path.lineTo(size.width * 0.08, size.height * 0.4);
    path.close();

    canvas.drawPath(path, paint);

    // Add some internal boundaries
    paint.color = AppTheme.borderLight.withValues(alpha: 0.2);
    paint.strokeWidth = 0.5;

    // Vertical lines
    canvas.drawLine(
      Offset(size.width * 0.3, size.height * 0.2),
      Offset(size.width * 0.3, size.height * 0.8),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.6, size.height * 0.25),
      Offset(size.width * 0.6, size.height * 0.75),
      paint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(size.width * 0.15, size.height * 0.4),
      Offset(size.width * 0.85, size.height * 0.4),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 0.2, size.height * 0.7),
      Offset(size.width * 0.8, size.height * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
