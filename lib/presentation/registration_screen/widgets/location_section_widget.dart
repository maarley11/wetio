import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class LocationSectionWidget extends StatefulWidget {
  final Function(String location) onLocationSelected;
  final bool isLoading;

  const LocationSectionWidget({
    super.key,
    required this.onLocationSelected,
    this.isLoading = false,
  });

  @override
  State<LocationSectionWidget> createState() => _LocationSectionWidgetState();
}

class _LocationSectionWidgetState extends State<LocationSectionWidget> {
  String? _selectedLocation;
  final TextEditingController _locationController = TextEditingController();

  // Popular cities in Senegal
  final List<String> _senegalCities = [
    'Dakar',
    'Thiès',
    'Kaolack',
    'Ziguinchor',
    'Saint-Louis',
    'Touba',
    'Rufisque',
    'Mbour',
    'Diourbel',
    'Louga',
    'Tambacounda',
    'Kolda',
    'Fatick',
    'Kaffrine',
    'Kédougou',
    'Matam',
    'Sédhiou',
  ];

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _showLocationPicker() {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.symmetric(vertical: 8.5),
              width: 40.0,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.5),
              child: Text(
                'Choisir votre ville',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),

            // Search field
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.5),
              child: TextField(
                controller: _locationController,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Rechercher une ville...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CustomIconWidget(
                      iconName: 'search',
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  filled: true,
                  fillColor: colorScheme.surface,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: colorScheme.outline, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: colorScheme.outline, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: colorScheme.primary, width: 2),
                  ),
                  hintStyle: GoogleFonts.inter(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                onChanged: (value) {
                  setState(() {}); // Rebuild to filter list
                },
              ),
            ),

            // Cities list
            Flexible(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                itemCount:
                    _getFilteredCities().length + 1, // +1 for custom option
                itemBuilder: (context, index) {
                  final filteredCities = _getFilteredCities();

                  if (index == filteredCities.length) {
                    // Custom location option
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CustomIconWidget(
                          iconName: 'edit_location',
                          color: colorScheme.secondary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Saisir manuellement',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        'Entrer une ville personnalisée',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _showCustomLocationDialog();
                      },
                    );
                  }

                  final city = filteredCities[index];
                  final isSelected = _selectedLocation == city;

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.2)
                            : colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: 'location_city',
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      city,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    trailing: isSelected
                        ? CustomIconWidget(
                            iconName: 'check_circle',
                            color: colorScheme.primary,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      _selectLocation(city);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),

            SizedBox(height: 17.0),
          ],
        ),
      ),
    );
  }

  List<String> _getFilteredCities() {
    final query = _locationController.text.toLowerCase();
    if (query.isEmpty) {
      return _senegalCities;
    }
    return _senegalCities
        .where((city) => city.toLowerCase().contains(query))
        .toList();
  }

  void _showCustomLocationDialog() {
    final colorScheme = Theme.of(context).colorScheme;
    final customController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Saisir votre ville',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        content: TextField(
          controller: customController,
          autofocus: true,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'Nom de votre ville',
            filled: true,
            fillColor: colorScheme.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.outline, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            hintStyle: GoogleFonts.inter(
              color: colorScheme.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final customLocation = customController.text.trim();
              if (customLocation.isNotEmpty) {
                _selectLocation(customLocation);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Valider',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectLocation(String location) {
    setState(() {
      _selectedLocation = location;
    });
    widget.onLocationSelected(location);
    HapticFeedback.lightImpact();
  }

  void _clearLocation() {
    setState(() {
      _selectedLocation = null;
    });
    widget.onLocationSelected('');
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CustomIconWidget(
              iconName: 'location_on',
              color: colorScheme.primary,
              size: 20,
            ),
            SizedBox(width: 8.0),
            Text(
              'Localisation',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),

        SizedBox(height: 8.5),

        Text(
          'Optionnelle - aide à filtrer les produits de votre région',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
          ),
        ),

        SizedBox(height: 17.0),

        // Location selection button
        GestureDetector(
          onTap: widget.isLoading ? null : _showLocationPicker,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.8),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedLocation != null
                    ? colorScheme.primary
                    : colorScheme.outline,
                width: _selectedLocation != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.surface,
            ),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: _selectedLocation != null
                      ? 'location_city'
                      : 'add_location',
                  color: _selectedLocation != null
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    _selectedLocation ?? 'Choisir votre ville',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: _selectedLocation != null
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: _selectedLocation != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (_selectedLocation != null)
                  GestureDetector(
                    onTap: widget.isLoading ? null : _clearLocation,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: CustomIconWidget(
                        iconName: 'clear',
                        color: colorScheme.onSurfaceVariant,
                        size: 16,
                      ),
                    ),
                  )
                else
                  CustomIconWidget(
                    iconName: 'expand_more',
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
