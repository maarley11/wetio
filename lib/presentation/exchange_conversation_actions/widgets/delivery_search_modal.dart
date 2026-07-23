import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class DeliverySearchModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onDeliveryPartnerSelected;

  const DeliverySearchModal({
    super.key,
    required this.onDeliveryPartnerSelected,
  });

  @override
  State<DeliverySearchModal> createState() => _DeliverySearchModalState();
}

class _DeliverySearchModalState extends State<DeliverySearchModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  bool _isSearching = false;
  String _selectedRegion = 'Dakar';

  final List<String> _regions = [
    'Dakar',
    'Guédiawaye',
    'Pikine',
    'Rufisque',
    'Keur Massar',
  ];

  final List<Map<String, dynamic>> _availableDeliveryPartners = [
    {
      'id': '1',
      'name': 'Mamadou Diop',
      'rating': 4.8,
      'deliveries': 156,
      'vehicle': 'Moto',
      'estimatedTime': '15-25 min',
      'price': '1500 FCFA',
      'distance': '2.3 km',
      'avatar':
          'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
      'isVerified': true,
      'responseTime': '< 5 min',
    },
    {
      'id': '2',
      'name': 'Fatou Ba',
      'rating': 4.9,
      'deliveries': 243,
      'vehicle': 'Voiture',
      'estimatedTime': '20-30 min',
      'price': '2000 FCFA',
      'distance': '3.1 km',
      'avatar':
          'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
      'isVerified': true,
      'responseTime': '< 3 min',
    },
    {
      'id': '3',
      'name': 'Ousmane Seck',
      'rating': 4.6,
      'deliveries': 89,
      'vehicle': 'Moto',
      'estimatedTime': '10-20 min',
      'price': '1200 FCFA',
      'distance': '1.8 km',
      'avatar':
          'https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png',
      'isVerified': false,
      'responseTime': '< 10 min',
    },
  ];

  List<Map<String, dynamic>> _filteredPartners = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _searchDeliveryPartners();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  Future<void> _searchDeliveryPartners() async {
    setState(() {
      _isSearching = true;
      _filteredPartners = [];
    });

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 1500));

    setState(() {
      _filteredPartners = List.from(_availableDeliveryPartners);
      _isSearching = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectDeliveryPartner(Map<String, dynamic> partner) {
    HapticFeedback.mediumImpact();
    widget.onDeliveryPartnerSelected(partner);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: EdgeInsets.symmetric(vertical: 8.5),
                  width: 48.0,
                  height: 4.3,
                  decoration: BoxDecoration(
                    color: colorScheme.outline.withAlpha(77),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 17.0),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'local_shipping',
                        size: 24,
                        color: AppTheme.primaryGreen,
                      ),
                      SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Trouver un livreur',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Livreurs disponibles dans votre région',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Region Selector
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.0),
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundWhite,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'location_on',
                        size: 20,
                        color: AppTheme.primaryGreen,
                      ),
                      SizedBox(width: 8.0),
                      Text(
                        'Région: ',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedRegion,
                        underline: Container(),
                        items: _regions.map((region) {
                          return DropdownMenuItem(
                            value: region,
                            child: Text(
                              region,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedRegion = value;
                            });
                            _searchDeliveryPartners();
                          }
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 25.5),

                // Content
                Expanded(
                  child: _isSearching
                      ? _buildLoadingState()
                      : _buildDeliveryPartnersList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: AppTheme.primaryGreen),
        SizedBox(height: 25.5),
        Text(
          'Recherche de livreurs près de chez vous...',
          style:
              GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDeliveryPartnersList() {
    if (_filteredPartners.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'search_off',
            size: 48,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 17.0),
          Text(
            'Aucun livreur disponible',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            'Essayez une autre région',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _filteredPartners.length,
      itemBuilder: (context, index) {
        final partner = _filteredPartners[index];
        return _buildDeliveryPartnerCard(partner);
      },
    );
  }

  Widget _buildDeliveryPartnerCard(Map<String, dynamic> partner) {
    return GestureDetector(
      onTap: () => _selectDeliveryPartner(partner),
      child: Container(
        margin: EdgeInsets.only(bottom: 17.0),
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(51),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                // Avatar
                Container(
                  width: 60.0,
                  height: 60.0,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: Stack(
                    children: [
                      ClipOval(
                        child: CustomImageWidget(
                          imageUrl: partner['avatar'],
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (partner['isVerified'])
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4.0),
                            decoration: BoxDecoration(
                              color: AppTheme.successGreen,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CustomIconWidget(
                              iconName: 'verified',
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 12.0),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              partner['name'],
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              partner['price'],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.3),
                      Row(
                        children: [
                          CustomIconWidget(
                            iconName: 'star',
                            size: 14,
                            color: AppTheme.warningOrange,
                          ),
                          SizedBox(width: 4.0),
                          Text(
                            '${partner['rating']} (${partner['deliveries']} livraisons)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: 17.0),

            // Details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'directions_bike',
                    partner['vehicle'],
                    AppTheme.primaryGreen,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'schedule',
                    partner['estimatedTime'],
                    AppTheme.primaryOrange,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'near_me',
                    partner['distance'],
                    AppTheme.primaryOrange,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.5),

            // Response Time
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.5),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomIconWidget(
                    iconName: 'flash_on',
                    size: 16,
                    color: AppTheme.successGreen,
                  ),
                  SizedBox(width: 4.0),
                  Text(
                    'Répond en ${partner['responseTime']}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.successGreen,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String icon, String text, Color color) {
    return Column(
      children: [
        CustomIconWidget(iconName: icon, size: 20, color: color),
        SizedBox(height: 4.3),
        Text(
          text,
          style:
              GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
