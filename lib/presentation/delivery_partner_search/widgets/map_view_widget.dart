import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class MapViewWidget extends StatefulWidget {
  final List<Map<String, dynamic>> partners;
  final Function(Map<String, dynamic>) onPartnerTap;

  const MapViewWidget({
    super.key,
    required this.partners,
    required this.onPartnerTap,
  });

  @override
  State<MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<MapViewWidget> {
  Map<String, dynamic>? _selectedPartner;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map container (placeholder)
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.borderLight.withValues(alpha: 0.3),
            image: const DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1569336415962-a4bd9f69cd83?w=800&h=600&fit=crop',
              ),
              fit: BoxFit.cover,
              opacity: 0.3,
            ),
          ),
          child: Stack(
            children: [
              // Map overlay with grid pattern
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite.withValues(alpha: 0.8),
                ),
                child: CustomPaint(
                  painter: GridPainter(),
                  size: Size.infinite,
                ),
              ),

              // Partner markers
              ...widget.partners.asMap().entries.map((entry) {
                final index = entry.key;
                final partner = entry.value;

                // Simulate positions on the map
                final left = 50.0 +
                    (index * 80.0) % (MediaQuery.of(context).size.width - 100);
                final top = 100.0 +
                    (index * 60.0) % (MediaQuery.of(context).size.height - 250);

                return Positioned(
                  left: left,
                  top: top,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPartner = partner;
                      });
                      widget.onPartnerTap(partner);
                    },
                    child: _buildMarker(partner),
                  ),
                );
              }).toList(),
            ],
          ),
        ),

        // Map controls
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              _buildMapButton(Icons.my_location, 'Ma position'),
              const SizedBox(height: 8),
              _buildMapButton(Icons.add, 'Zoom +'),
              const SizedBox(height: 8),
              _buildMapButton(Icons.remove, 'Zoom -'),
            ],
          ),
        ),

        // Legend
        Positioned(
          bottom: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(8),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Légende',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildLegendItem(AppTheme.successGreen, 'Disponible'),
                _buildLegendItem(AppTheme.errorRed, 'Occupé'),
                _buildLegendItem(AppTheme.primaryOrange, 'En route'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMarker(Map<String, dynamic> partner) {
    final isSelected = _selectedPartner?['id'] == partner['id'];
    final isAvailable = partner['isAvailable'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.identity()..scale(isSelected ? 1.2 : 1.0),
      child: Column(
        children: [
          // Marker
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isAvailable ? AppTheme.successGreen : AppTheme.errorRed,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.surfaceWhite,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(17),
              child: Image.network(
                partner['profileImage'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    _getVehicleIcon(partner['vehicleType']),
                    color: AppTheme.surfaceWhite,
                    size: 20,
                  );
                },
              ),
            ),
          ),

          // Info popup
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowLight,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    partner['name'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        color: AppTheme.warningOrange,
                        size: 12,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${partner['rating']}',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${partner['basePrice']} FCFA',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryGreen,
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

  Widget _buildMapButton(IconData icon, String tooltip) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.textPrimary, size: 20),
        onPressed: () {
          // Map control functionality
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tooltip),
              duration: const Duration(seconds: 1),
            ),
          );
        },
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType) {
      case 'bike':
        return Icons.pedal_bike;
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'car':
        return Icons.directions_car;
      default:
        return Icons.delivery_dining;
    }
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.borderLight.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    const gridSize = 50.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
