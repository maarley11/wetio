import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/coverage_area_widget.dart';
import './widgets/delivery_results_widget.dart';
import './widgets/region_selector_widget.dart';
import './widgets/search_parameters_widget.dart';
import './widgets/senegal_map_widget.dart';

class RegionalDeliverySearch extends StatefulWidget {
  const RegionalDeliverySearch({super.key});

  @override
  State<RegionalDeliverySearch> createState() => _RegionalDeliverySearchState();
}

class _RegionalDeliverySearchState extends State<RegionalDeliverySearch> {
  bool _isLoading = false;
  String _selectedRegion = 'Dakar';
  String _selectedNeighborhood = '';
  double _deliveryRadius = 10.0;
  String _serviceType = 'all';
  String _availabilitySlot = 'all';
  String _sortBy = 'proximity';
  Position? _currentPosition;

  final List<String> _senegalRegions = [
    'Dakar',
    'Thiès',
    'Saint-Louis',
    'Kaolack',
    'Tambacounda',
    'Ziguinchor',
    'Diourbel',
    'Louga',
    'Fatick',
    'Kolda',
    'Matam',
    'Kaffrine',
    'Kédougou',
    'Sédhiou',
  ];

  final Map<String, List<String>> _regionNeighborhoods = {
    'Dakar': [
      'Plateau',
      'Médina',
      'Fann',
      'Point E',
      'Mermoz',
      'Sacré-Cœur',
      'Ouakam',
      'Yoff',
      'Ngor',
      'Almadies',
      'HLM',
      'Grand Dakar',
    ],
    'Thiès': [
      'Thiès Centre',
      'Thiès Nord',
      'Thiès Sud',
      'Tivaouane',
      'Mékhé',
      'Khombole',
    ],
    'Saint-Louis': [
      'Saint-Louis Centre',
      'Sor',
      'Ndar Toute',
      'Bango',
      'Pikine Saint-Louis',
    ],
    'Kaolack': [
      'Kaolack Centre',
      'Médina Baye',
      'Léona',
      'Dialakoto',
    ],
  };

  List<Map<String, dynamic>> _mockDeliveryPartners = [
    {
      'id': '1',
      'name': 'Mamadou Ba',
      'region': 'Dakar',
      'neighborhood': 'Plateau',
      'rating': 4.9,
      'deliveries': 342,
      'vehicle': 'Moto',
      'availability': 'En ligne',
      'distance': 2.1,
      'estimatedTime': '15-20 min',
      'pricing': {
        'base': 1500,
        'perKm': 300,
        'express': 2500,
      },
      'specialties': ['Nourriture', 'Documents', 'Express'],
      'coverageZones': ['Plateau', 'Médina', 'Fann'],
      'location': {'lat': 14.6928, 'lng': -17.4467},
      'profileImage':
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
    },
    {
      'id': '2',
      'name': 'Fatou Diop',
      'region': 'Dakar',
      'neighborhood': 'Almadies',
      'rating': 4.7,
      'deliveries': 156,
      'vehicle': 'Voiture',
      'availability': 'En ligne',
      'distance': 8.4,
      'estimatedTime': '20-30 min',
      'pricing': {
        'base': 2500,
        'perKm': 400,
        'express': 4000,
      },
      'specialties': ['Gros volumes', 'Longue distance'],
      'coverageZones': ['Almadies', 'Ngor', 'Yoff', 'Ouakam'],
      'location': {'lat': 14.7167, 'lng': -17.4833},
      'profileImage':
          'https://images.unsplash.com/photo-1494790108755-2616b612b647?w=150&h=150&fit=crop&crop=face',
    },
    {
      'id': '3',
      'name': 'Ibrahima Sarr',
      'region': 'Thiès',
      'neighborhood': 'Thiès Centre',
      'rating': 4.8,
      'deliveries': 89,
      'vehicle': 'Moto',
      'availability': 'Hors ligne',
      'distance': 0.0, // Will be calculated
      'estimatedTime': 'Indisponible',
      'pricing': {
        'base': 1200,
        'perKm': 250,
        'express': 2000,
      },
      'specialties': ['Nourriture', 'Pharmacie'],
      'coverageZones': ['Thiès Centre', 'Thiès Nord'],
      'location': {'lat': 14.7886, 'lng': -16.9317},
      'profileImage':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
    },
  ];

  List<Map<String, dynamic>> get _filteredPartners {
    return _mockDeliveryPartners.where((partner) {
      // Region filter
      if (partner['region'] != _selectedRegion) return false;

      // Neighborhood filter
      if (_selectedNeighborhood.isNotEmpty &&
          partner['neighborhood'] != _selectedNeighborhood) {
        return false;
      }

      // Service type filter
      if (_serviceType != 'all') {
        List<String> specialties = List<String>.from(partner['specialties']);
        switch (_serviceType) {
          case 'food':
            if (!specialties.contains('Nourriture')) return false;
            break;
          case 'express':
            if (!specialties.contains('Express')) return false;
            break;
          case 'bulk':
            if (!specialties.contains('Gros volumes')) return false;
            break;
        }
      }

      // Availability filter
      if (_availabilitySlot == 'online' &&
          partner['availability'] != 'En ligne') {
        return false;
      }

      // Radius filter (simplified - in real app would use proper geo calculations)
      if (partner['distance'] > _deliveryRadius) return false;

      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      // Handle location error silently
    }
  }

  void _onRegionChanged(String region) {
    setState(() {
      _selectedRegion = region;
      _selectedNeighborhood = ''; // Reset neighborhood when region changes
    });
  }

  void _onNeighborhoodChanged(String neighborhood) {
    setState(() {
      _selectedNeighborhood = neighborhood;
    });
  }

  void _onParametersChanged(Map<String, dynamic> params) {
    setState(() {
      _deliveryRadius = params['radius'] ?? _deliveryRadius;
      _serviceType = params['serviceType'] ?? _serviceType;
      _availabilitySlot = params['availability'] ?? _availabilitySlot;
      _sortBy = params['sortBy'] ?? _sortBy;
    });
  }

  Future<void> _refreshResults() async {
    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _addToFavoriteRegions() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_selectedRegion ajouté aux régions favorites'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPartners = _filteredPartners;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Text(
          'Recherche Régionale',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.favorite_border,
              color: AppTheme.textPrimary,
            ),
            onPressed: _addToFavoriteRegions,
            tooltip: 'Sauvegarder région',
          ),
          IconButton(
            icon: const Icon(
              Icons.my_location,
              color: AppTheme.primaryGreen,
            ),
            onPressed: _getCurrentLocation,
            tooltip: 'Ma position',
          ),
        ],
      ),
      body: Column(
        children: [
          // Interactive regional map
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            child: SenegalMapWidget(
              selectedRegion: _selectedRegion,
              deliveryPartners: filteredPartners,
              onRegionTap: _onRegionChanged,
              currentPosition: _currentPosition,
            ),
          ),

          // Region selector and filters
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                RegionSelectorWidget(
                  selectedRegion: _selectedRegion,
                  selectedNeighborhood: _selectedNeighborhood,
                  regions: _senegalRegions,
                  neighborhoods: _regionNeighborhoods[_selectedRegion] ?? [],
                  onRegionChanged: _onRegionChanged,
                  onNeighborhoodChanged: _onNeighborhoodChanged,
                ),
                const SizedBox(height: 16),
                SearchParametersWidget(
                  deliveryRadius: _deliveryRadius,
                  serviceType: _serviceType,
                  availabilitySlot: _availabilitySlot,
                  sortBy: _sortBy,
                  onParametersChanged: _onParametersChanged,
                ),
              ],
            ),
          ),

          // Coverage area visualization
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CoverageAreaWidget(
              selectedRegion: _selectedRegion,
              availablePartners: filteredPartners.length,
              radius: _deliveryRadius,
            ),
          ),

          // Results section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceWhite,
              border: Border(
                bottom: BorderSide(color: AppTheme.borderLight, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredPartners.length} livreurs dans $_selectedRegion',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (filteredPartners.isNotEmpty)
                  Text(
                    'Tarif moyen: ${_calculateAveragePrice(filteredPartners)} FCFA',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Delivery results
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  )
                : filteredPartners.isEmpty
                    ? _buildEmptyState()
                    : DeliveryResultsWidget(
                        partners: filteredPartners,
                        sortBy: _sortBy,
                        onRefresh: _refreshResults,
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refreshResults,
        backgroundColor: AppTheme.primaryGreen,
        icon: const Icon(
          Icons.refresh,
          color: AppTheme.surfaceWhite,
        ),
        label: Text(
          'Actualiser',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.surfaceWhite,
          ),
        ),
      ),
    );
  }

  int _calculateAveragePrice(List<Map<String, dynamic>> partners) {
    if (partners.isEmpty) return 0;
    final total = partners
        .map((p) => p['pricing']['base'] as int)
        .reduce((a, b) => a + b);
    return (total / partners.length).round();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun livreur disponible',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'dans $_selectedRegion',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez une autre région ou élargissez votre rayon de recherche',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _deliveryRadius = 25.0;
                _serviceType = 'all';
                _availabilitySlot = 'all';
              });
            },
            icon: const Icon(Icons.zoom_out_map, size: 18),
            label: Text(
              'Élargir la recherche',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
