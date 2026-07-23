import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/booking_bottom_sheet.dart';
import './widgets/delivery_partner_card.dart';
import './widgets/map_view_widget.dart';
import './widgets/search_filter_widget.dart';

class DeliveryPartnerSearch extends StatefulWidget {
  const DeliveryPartnerSearch({super.key});

  @override
  State<DeliveryPartnerSearch> createState() => _DeliveryPartnerSearchState();
}

class _DeliveryPartnerSearchState extends State<DeliveryPartnerSearch> {
  bool _isMapView = false;
  bool _isLoading = false;
  String _searchQuery = '';
  String _sortBy = 'proximity'; // proximity | rating | price
  Map<String, dynamic> _filters = {
    'vehicleType': '',
    'priceRange': const RangeValues(1000, 8000),
    'minRating': 0.0,
    'maxDistance': 15.0,
    'isAvailable': true,
  };

  List<Map<String, dynamic>> _deliveryPartners = [
    {
      'id': '1',
      'dbId': null,
      'name': 'Kouassi Jean',
      'rating': 4.8,
      'reviewCount': 156,
      'vehicleType': 'motorcycle',
      'vehicleModel': 'Yamaha MT-125',
      'distance': 2.3,
      'estimatedTime': '15-20 min',
      'basePrice': 2500,
      'isAvailable': true,
      'profileImage':
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face',
      'location': {'lat': 5.3364, 'lng': -4.0267},
      'coverageZones': ['Cocody', 'Plateau', 'Marcory'],
      'specialties': ['Nourriture', 'Colis express'],
    },
    {
      'id': '2',
      'dbId': null,
      'name': 'Fatou Diallo',
      'rating': 4.9,
      'reviewCount': 203,
      'vehicleType': 'car',
      'vehicleModel': 'Toyota Yaris',
      'distance': 3.7,
      'estimatedTime': '10-15 min',
      'basePrice': 3500,
      'isAvailable': true,
      'profileImage':
          'https://images.unsplash.com/photo-1494790108755-2616b612b647?w=150&h=150&fit=crop&crop=face',
      'location': {'lat': 5.3097, 'lng': -4.0120},
      'coverageZones': ['Yopougon', 'Adjamé', 'Abobo'],
      'specialties': ['Gros volumes', 'Livraison longue distance'],
    },
    {
      'id': '3',
      'dbId': null,
      'name': 'Mamadou Traoré',
      'rating': 4.7,
      'reviewCount': 98,
      'vehicleType': 'bike',
      'vehicleModel': 'Vélo électrique',
      'distance': 1.2,
      'estimatedTime': '8-12 min',
      'basePrice': 1500,
      'isAvailable': true,
      'profileImage':
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face',
      'location': {'lat': 5.3411, 'lng': -4.0315},
      'coverageZones': ['Plateau', 'Treichville'],
      'specialties': ['Livraisons rapides', 'Documents'],
    },
    {
      'id': '4',
      'dbId': null,
      'name': 'Aminata Koné',
      'rating': 4.6,
      'reviewCount': 134,
      'vehicleType': 'motorcycle',
      'vehicleModel': 'Honda CB125',
      'distance': 4.1,
      'estimatedTime': '20-25 min',
      'basePrice': 2200,
      'isAvailable': false,
      'profileImage':
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face',
      'location': {'lat': 5.2893, 'lng': -3.9716},
      'coverageZones': ['Koumassi', 'Port-Bouët'],
      'specialties': ['Pharmacie', 'Nourriture'],
    },
  ];

  List<Map<String, dynamic>> get _filteredAndSortedPartners {
    var result = _deliveryPartners.where((partner) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!partner['name'].toLowerCase().contains(query) &&
            !(partner['coverageZones'] as List).any(
              (zone) => zone.toLowerCase().contains(query),
            )) {
          return false;
        }
      }
      if (_filters['vehicleType'].isNotEmpty &&
          partner['vehicleType'] != _filters['vehicleType']) return false;
      final priceRange = _filters['priceRange'] as RangeValues;
      if (partner['basePrice'] < priceRange.start ||
          partner['basePrice'] > priceRange.end) return false;
      if (partner['rating'] < _filters['minRating']) return false;
      if (partner['distance'] > _filters['maxDistance']) return false;
      if (_filters['isAvailable'] && !partner['isAvailable']) return false;
      return true;
    }).toList();

    // Smart sort
    switch (_sortBy) {
      case 'proximity':
        result.sort(
          (a, b) =>
              (a['distance'] as double).compareTo(b['distance'] as double),
        );
        break;
      case 'rating':
        result.sort(
          (a, b) => (b['rating'] as double).compareTo(a['rating'] as double),
        );
        break;
      case 'price':
        result.sort(
          (a, b) => (a['basePrice'] as int).compareTo(b['basePrice'] as int),
        );
        break;
    }
    return result;
  }

  void _onSearchChanged(String query) => setState(() => _searchQuery = query);
  void _onFiltersChanged(Map<String, dynamic> filters) =>
      setState(() => _filters = filters);
  void _toggleView() => setState(() => _isMapView = !_isMapView);

  void _showBookingBottomSheet(Map<String, dynamic> partner) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingBottomSheet(partner: partner),
    );
  }

  Future<void> _refreshPartners() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('delivery_persons')
          .select('*, user_profiles(full_name, phone, avatar_url)')
          .eq('availability_status', 'available')
          .eq('status', 'approved');

      if (mounted && (response as List).isNotEmpty) {
        final dbPartners = response.map((dp) {
          final profile = dp['user_profiles'] as Map<String, dynamic>?;
          return {
            'id': dp['id'],
            'dbId': dp['id'],
            'name': profile?['full_name'] ?? 'Livreur',
            'rating': (dp['average_rating'] as num?)?.toDouble() ?? 0.0,
            'reviewCount': dp['total_ratings'] ?? 0,
            'vehicleType': dp['vehicle_type'] ?? 'motorcycle',
            'vehicleModel': dp['license_plate'] ?? 'Véhicule',
            'distance': 2.0,
            'estimatedTime': '15-20 min',
            'basePrice': dp['base_price_fcfa'] ?? 2000,
            'isAvailable': dp['availability_status'] == 'available',
            'profileImage': profile?['avatar_url'] ?? '',
            'location': {
              'lat': dp['current_lat'] ?? 0.0,
              'lng': dp['current_lng'] ?? 0.0,
            },
            'coverageZones':
                (dp['coverage_areas'] as List?)?.cast<String>() ?? [],
            'specialties':
                (dp['delivery_types'] as List?)?.cast<String>() ?? [],
          };
        }).toList();
        setState(() => _deliveryPartners = dbPartners);
      }
    } catch (e) {
      debugPrint('Error loading delivery partners: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredPartners = _filteredAndSortedPartners;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Text(
          'Trouver un Livreur',
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
            icon: Icon(
              _isMapView ? Icons.list : Icons.map,
              color: AppTheme.textPrimary,
            ),
            onPressed: _toggleView,
          ),
        ],
      ),
      body: Column(
        children: [
          SearchFilterWidget(
            onSearchChanged: _onSearchChanged,
            onFiltersChanged: _onFiltersChanged,
            initialFilters: _filters,
          ),

          // Smart sort chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppTheme.surfaceWhite,
            child: Row(
              children: [
                Text(
                  'Trier : ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                _buildSortChip('proximity', Icons.near_me, 'Proximité'),
                const SizedBox(width: 8),
                _buildSortChip('rating', Icons.star, 'Note'),
                const SizedBox(width: 8),
                _buildSortChip('price', Icons.attach_money, 'Prix'),
              ],
            ),
          ),

          // Results header
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
                  '${filteredPartners.length} livreurs disponibles',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (_searchQuery.isNotEmpty || _hasActiveFilters())
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _filters = {
                          'vehicleType': '',
                          'priceRange': const RangeValues(1000, 8000),
                          'minRating': 0.0,
                          'maxDistance': 15.0,
                          'isAvailable': true,
                        };
                      });
                    },
                    child: Text(
                      'Effacer filtres',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  )
                : _isMapView
                    ? MapViewWidget(
                        partners: filteredPartners,
                        onPartnerTap: _showBookingBottomSheet,
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshPartners,
                        color: AppTheme.primaryGreen,
                        child: filteredPartners.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredPartners.length,
                                itemBuilder: (context, index) {
                                  final partner = filteredPartners[index];
                                  return DeliveryPartnerCard(
                                    partner: partner,
                                    onTap: () =>
                                        _showBookingBottomSheet(partner),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshPartners,
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.refresh, color: AppTheme.surfaceWhite),
      ),
    );
  }

  Widget _buildSortChip(String value, IconData icon, String label) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () => setState(() => _sortBy = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryGreen
              : AppTheme.primaryGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppTheme.primaryGreen,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasActiveFilters() {
    return _filters['vehicleType'].isNotEmpty ||
        _filters['priceRange'] != const RangeValues(1000, 8000) ||
        _filters['minRating'] != 0.0 ||
        _filters['maxDistance'] != 15.0 ||
        !_filters['isAvailable'];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun livreur trouvé',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de modifier vos critères de recherche',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _filters = {
                  'vehicleType': '',
                  'priceRange': const RangeValues(1000, 8000),
                  'minRating': 0.0,
                  'maxDistance': 15.0,
                  'isAvailable': true,
                };
              });
            },
            child: Text(
              'Réinitialiser les filtres',
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
