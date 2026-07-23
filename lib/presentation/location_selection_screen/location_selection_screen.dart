import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedLocation;
  bool _isLoadingCurrentLocation = false;
  String _currentLocation = 'Dakar, Sénégal';

  // Mock data for Senegal cities
  final List<Map<String, dynamic>> _senegalCities = [
    {
      'name': 'Dakar',
      'region': 'Dakar',
      'activeUsers': 1250,
      'distance': '0 km',
      'isPopular': true,
    },
    {
      'name': 'Thiès',
      'region': 'Thiès',
      'activeUsers': 450,
      'distance': '70 km',
      'isPopular': true,
    },
    {
      'name': 'Saint-Louis',
      'region': 'Saint-Louis',
      'activeUsers': 320,
      'distance': '265 km',
      'isPopular': true,
    },
    {
      'name': 'Kaolack',
      'region': 'Kaolack',
      'activeUsers': 280,
      'distance': '194 km',
      'isPopular': true,
    },
    {
      'name': 'Ziguinchor',
      'region': 'Ziguinchor',
      'activeUsers': 210,
      'distance': '452 km',
      'isPopular': false,
    },
    {
      'name': 'Mbour',
      'region': 'Thiès',
      'activeUsers': 195,
      'distance': '83 km',
      'isPopular': false,
    },
    {
      'name': 'Tambacounda',
      'region': 'Tambacounda',
      'activeUsers': 165,
      'distance': '434 km',
      'isPopular': false,
    },
    {
      'name': 'Rufisque',
      'region': 'Dakar',
      'activeUsers': 180,
      'distance': '25 km',
      'isPopular': false,
    },
    {
      'name': 'Pikine',
      'region': 'Dakar',
      'activeUsers': 420,
      'distance': '15 km',
      'isPopular': false,
    },
    {
      'name': 'Guédiawaye',
      'region': 'Dakar',
      'activeUsers': 310,
      'distance': '18 km',
      'isPopular': false,
    },
  ];

  List<Map<String, dynamic>> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    _filteredCities = List.from(_senegalCities);
    _selectedLocation = _currentLocation;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCities(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCities = List.from(_senegalCities);
      } else {
        _filteredCities = _senegalCities
            .where((city) =>
                city['name'].toLowerCase().contains(query.toLowerCase()) ||
                city['region'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoadingCurrentLocation = true;
    });

    HapticFeedback.lightImpact();

    // Simulate GPS detection
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _selectedLocation = 'Dakar, Sénégal';
        _isLoadingCurrentLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Position actuelle détectée'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmSelection() {
    if (_selectedLocation != null) {
      HapticFeedback.lightImpact();
      Navigator.pop(context, _selectedLocation);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: CustomAppBar(
        title: 'Sélectionner une localisation',
        variant: CustomAppBarVariant.primary,
      ),
      body: Column(
        children: [
          // Current Location Section
          _buildCurrentLocationSection(theme, colorScheme),

          // Search Bar
          _buildSearchBar(theme, colorScheme),

          // City List
          Expanded(
            child: _buildCityList(theme, colorScheme),
          ),

          // Confirm Button
          _buildConfirmButton(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildCurrentLocationSection(
      ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.all(16.0),
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'my_location',
                  size: 20,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Position actuelle',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.3),
                    Text(
                      _currentLocation,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 17.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoadingCurrentLocation ? null : _useCurrentLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoadingCurrentLocation
                  ? SizedBox(
                      height: 17.0,
                      width: 17.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Utiliser ma position actuelle',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.5),
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.5),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'search',
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _filterCities,
              decoration: InputDecoration(
                hintText: 'Rechercher une ville...',
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _filterCities('');
              },
              child: CustomIconWidget(
                iconName: 'close',
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCityList(ThemeData theme, ColorScheme colorScheme) {
    if (_filteredCities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'location_off',
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            SizedBox(height: 17.0),
            Text(
              'Aucune ville trouvée',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 8.5),
            Text(
              'Essayez une autre recherche',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.5),
      itemCount: _filteredCities.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: colorScheme.outline.withValues(alpha: 0.2),
      ),
      itemBuilder: (context, index) {
        final city = _filteredCities[index];
        final isSelected =
            _selectedLocation == '${city['name']}, ${city['region']}';

        return InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedLocation = '${city['name']}, ${city['region']}';
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 17.0, horizontal: 8.0),
            child: Row(
              children: [
                Radio<String>(
                  value: '${city['name']}, ${city['region']}',
                  groupValue: _selectedLocation,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _selectedLocation = value;
                    });
                  },
                  activeColor: AppTheme.primaryGreen,
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            city['name'],
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.primaryGreen
                                  : colorScheme.onSurface,
                            ),
                          ),
                          if (city['isPopular'] == true) ...[
                            SizedBox(width: 8.0),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryOrange
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Populaire',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.primaryOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 4.3),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'people',
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 4.0),
                          Text(
                            '${city['activeUsers']} utilisateurs actifs',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(width: 12.0),
                          CustomIconWidget(
                            iconName: 'navigation',
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          SizedBox(width: 4.0),
                          Text(
                            city['distance'],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmButton(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedLocation != null ? _confirmSelection : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 15.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor:
                      colorScheme.outline.withValues(alpha: 0.2),
                ),
                child: Text(
                  'Confirmer la sélection',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.5),
            TextButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Text(
                'Annuler',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
