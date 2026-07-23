import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class SearchParametersWidget extends StatefulWidget {
  final double deliveryRadius;
  final String serviceType;
  final String availabilitySlot;
  final String sortBy;
  final Function(Map<String, dynamic>) onParametersChanged;

  const SearchParametersWidget({
    super.key,
    required this.deliveryRadius,
    required this.serviceType,
    required this.availabilitySlot,
    required this.sortBy,
    required this.onParametersChanged,
  });

  @override
  State<SearchParametersWidget> createState() => _SearchParametersWidgetState();
}

class _SearchParametersWidgetState extends State<SearchParametersWidget> {
  bool _isExpanded = false;
  late double _radius;
  late String _serviceType;
  late String _availability;
  late String _sortBy;

  @override
  void initState() {
    super.initState();
    _radius = widget.deliveryRadius;
    _serviceType = widget.serviceType;
    _availability = widget.availabilitySlot;
    _sortBy = widget.sortBy;
  }

  void _updateParameters() {
    widget.onParametersChanged({
      'radius': _radius,
      'serviceType': _serviceType,
      'availability': _availability,
      'sortBy': _sortBy,
    });
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
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with expand/collapse
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Paramètres de recherche',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_radius.round()} km',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            const Divider(height: 1, color: AppTheme.borderLight),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery radius slider
                  Text(
                    'Rayon de livraison',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: _radius,
                      min: 1.0,
                      max: 50.0,
                      divisions: 49,
                      activeColor: AppTheme.primaryGreen,
                      inactiveColor: AppTheme.borderLight,
                      label: '${_radius.round()} km',
                      onChanged: (value) {
                        setState(() {
                          _radius = value;
                        });
                        _updateParameters();
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 km',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      Text('50 km',
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Service type selection
                  Text(
                    'Type de service',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildServiceTypeChip('all', 'Tous', Icons.all_inclusive),
                      _buildServiceTypeChip(
                          'food', 'Nourriture', Icons.restaurant),
                      _buildServiceTypeChip(
                          'express', 'Express', Icons.flash_on),
                      _buildServiceTypeChip(
                          'bulk', 'Gros volumes', Icons.inventory),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Availability time slots
                  Text(
                    'Disponibilité',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildAvailabilityChip('all', 'Tous', Icons.schedule),
                      _buildAvailabilityChip(
                          'online', 'En ligne', Icons.online_prediction),
                      _buildAvailabilityChip(
                          'morning', 'Matin (6h-12h)', Icons.wb_sunny),
                      _buildAvailabilityChip('afternoon',
                          'Après-midi (12h-18h)', Icons.wb_sunny_outlined),
                      _buildAvailabilityChip(
                          'evening', 'Soir (18h-22h)', Icons.nights_stay),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Sort options
                  Text(
                    'Trier par',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderLight),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: AppTheme.textSecondary),
                        style: GoogleFonts.inter(
                            fontSize: 14, color: AppTheme.textPrimary),
                        items: const [
                          DropdownMenuItem(
                              value: 'proximity', child: Text('Distance')),
                          DropdownMenuItem(
                              value: 'rating', child: Text('Note')),
                          DropdownMenuItem(value: 'price', child: Text('Prix')),
                          DropdownMenuItem(
                              value: 'deliveries',
                              child: Text('Nombre de livraisons')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _sortBy = value;
                            });
                            _updateParameters();
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Quick presets
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Préréglages rapides',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: _buildPresetButton('Proximité',
                                    () => _applyProximityPreset())),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _buildPresetButton('Économique',
                                    () => _applyEconomicPreset())),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _buildPresetButton(
                                    'Rapide', () => _applyFastPreset())),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceTypeChip(String value, String label, IconData icon) {
    final isSelected = _serviceType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _serviceType = value;
        });
        _updateParameters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color:
                  isSelected ? AppTheme.surfaceWhite : AppTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color:
                    isSelected ? AppTheme.surfaceWhite : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityChip(String value, String label, IconData icon) {
    final isSelected = _availability == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _availability = value;
        });
        _updateParameters();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryOrange : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryOrange : AppTheme.borderLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  isSelected ? AppTheme.surfaceWhite : AppTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color:
                    isSelected ? AppTheme.surfaceWhite : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryGreen,
          ),
        ),
      ),
    );
  }

  void _applyProximityPreset() {
    setState(() {
      _radius = 5.0;
      _serviceType = 'all';
      _sortBy = 'proximity';
    });
    _updateParameters();
  }

  void _applyEconomicPreset() {
    setState(() {
      _radius = 20.0;
      _serviceType = 'all';
      _sortBy = 'price';
    });
    _updateParameters();
  }

  void _applyFastPreset() {
    setState(() {
      _radius = 8.0;
      _serviceType = 'express';
      _availability = 'online';
      _sortBy = 'rating';
    });
    _updateParameters();
  }
}
