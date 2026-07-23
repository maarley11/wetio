import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class SearchFilterWidget extends StatefulWidget {
  final Function(String) onSearchChanged;
  final Function(Map<String, dynamic>) onFiltersChanged;
  final Map<String, dynamic> initialFilters;

  const SearchFilterWidget({
    super.key,
    required this.onSearchChanged,
    required this.onFiltersChanged,
    required this.initialFilters,
  });

  @override
  State<SearchFilterWidget> createState() => _SearchFilterWidgetState();
}

class _SearchFilterWidgetState extends State<SearchFilterWidget> {
  final TextEditingController _searchController = TextEditingController();
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.initialFilters);
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    );
  }

  Widget _buildFilterBottomSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: StatefulBuilder(
        builder: (context, setModalState) {
          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filtres de recherche',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _filters = {
                            'vehicleType': '',
                            'priceRange': const RangeValues(1000, 8000),
                            'minRating': 4.0,
                            'maxDistance': 15.0,
                            'isAvailable': true,
                          };
                        });
                      },
                      child: Text(
                        'Réinitialiser',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehicle type
                      Text(
                        'Type de véhicule',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          _buildVehicleTypeChip(
                              '', 'Tous', Icons.all_inclusive, setModalState),
                          const SizedBox(width: 8),
                          _buildVehicleTypeChip(
                              'bike', 'Vélo', Icons.pedal_bike, setModalState),
                          const SizedBox(width: 8),
                          _buildVehicleTypeChip('motorcycle', 'Moto',
                              Icons.two_wheeler, setModalState),
                          const SizedBox(width: 8),
                          _buildVehicleTypeChip('car', 'Voiture',
                              Icons.directions_car, setModalState),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Price range
                      Text(
                        'Fourchette de prix',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        '${_filters['priceRange'].start.round()} - ${_filters['priceRange'].end.round()} FCFA',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryGreen,
                        ),
                      ),

                      RangeSlider(
                        values: _filters['priceRange'],
                        min: 500,
                        max: 10000,
                        divisions: 19,
                        activeColor: AppTheme.primaryGreen,
                        inactiveColor: AppTheme.borderLight,
                        onChanged: (values) {
                          setModalState(() {
                            _filters['priceRange'] = values;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      // Rating
                      Text(
                        'Note minimum',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_filters['minRating'].toStringAsFixed(1)} étoiles',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                index < _filters['minRating']
                                    ? Icons.star
                                    : Icons.star_border,
                                color: AppTheme.warningOrange,
                                size: 20,
                              );
                            }),
                          ),
                        ],
                      ),

                      Slider(
                        value: _filters['minRating'],
                        min: 1.0,
                        max: 5.0,
                        divisions: 8,
                        activeColor: AppTheme.primaryGreen,
                        inactiveColor: AppTheme.borderLight,
                        onChanged: (value) {
                          setModalState(() {
                            _filters['minRating'] = value;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      // Distance
                      Text(
                        'Distance maximale',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        '${_filters['maxDistance'].round()} km',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryGreen,
                        ),
                      ),

                      Slider(
                        value: _filters['maxDistance'],
                        min: 1.0,
                        max: 50.0,
                        divisions: 49,
                        activeColor: AppTheme.primaryGreen,
                        inactiveColor: AppTheme.borderLight,
                        onChanged: (value) {
                          setModalState(() {
                            _filters['maxDistance'] = value;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      // Availability
                      SwitchListTile(
                        title: Text(
                          'Disponibles uniquement',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Afficher seulement les livreurs disponibles',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        value: _filters['isAvailable'],
                        onChanged: (value) {
                          setModalState(() {
                            _filters['isAvailable'] = value;
                          });
                        },
                        activeThumbColor: AppTheme.primaryGreen,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),

              // Apply button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  border: Border(
                    top: BorderSide(color: AppTheme.borderLight, width: 1),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onFiltersChanged(_filters);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Appliquer les filtres',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVehicleTypeChip(
      String type, String label, IconData icon, StateSetter setModalState) {
    final isSelected = _filters['vehicleType'] == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setModalState(() {
            _filters['vehicleType'] = type;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                : AppTheme.surfaceWhite,
            border: Border.all(
              color: isSelected ? AppTheme.primaryGreen : AppTheme.borderLight,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color:
                    isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou zone...',
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          widget.onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppTheme.primaryGreen, width: 2),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: widget.onSearchChanged,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.primaryGreen),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: AppTheme.primaryGreen),
              onPressed: _showFilterBottomSheet,
              tooltip: 'Filtres',
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
