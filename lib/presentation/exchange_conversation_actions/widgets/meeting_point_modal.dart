import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MeetingPointModal extends StatefulWidget {
  final Function(Map<String, dynamic>) onMeetingPointConfirmed;

  const MeetingPointModal({super.key, required this.onMeetingPointConfirmed});

  @override
  State<MeetingPointModal> createState() => _MeetingPointModalState();
}

class _MeetingPointModalState extends State<MeetingPointModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  String _selectedLocation = '';
  final TextEditingController _customLocationController =
      TextEditingController();

  final List<Map<String, dynamic>> _suggestedLocations = [
    {
      'id': 'place_independence',
      'name': 'Place de l\'Indépendance',
      'description': 'Centre-ville, lieu public sécurisé',
      'icon': 'location_city',
      'color': AppTheme.primaryGreen,
    },
    {
      'id': 'sea_plaza',
      'name': 'Sea Plaza',
      'description': 'Centre commercial populaire',
      'icon': 'shopping_mall',
      'color': AppTheme.successGreen,
    },
    {
      'id': 'sandaga_market',
      'name': 'Marché Sandaga',
      'description': 'Grand marché, très fréquenté',
      'icon': 'store',
      'color': AppTheme.primaryOrange,
    },
    {
      'id': 'mamelles_lighthouse',
      'name': 'Phare des Mamelles',
      'description': 'Point de repère emblématique',
      'icon': 'lighthouse',
      'color': AppTheme.warningOrange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
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

  @override
  void dispose() {
    _animationController.dispose();
    _customLocationController.dispose();
    super.dispose();
  }

  void _confirmMeetingPoint() {
    if (_selectedLocation.isEmpty &&
        _customLocationController.text.trim().isEmpty) {
      return;
    }

    Map<String, dynamic> meetingPoint;

    if (_selectedLocation.isNotEmpty) {
      final selected = _suggestedLocations.firstWhere(
        (location) => location['id'] == _selectedLocation,
      );
      meetingPoint = {
        'id': selected['id'],
        'name': selected['name'],
        'description': selected['description'],
        'type': 'suggested',
      };
    } else {
      meetingPoint = {
        'id': 'custom',
        'name': _customLocationController.text.trim(),
        'description': 'Lieu personnalisé',
        'type': 'custom',
      };
    }

    HapticFeedback.mediumImpact();
    widget.onMeetingPointConfirmed(meetingPoint);
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
                        iconName: 'handshake',
                        size: 24,
                        color: AppTheme.primaryOrange,
                      ),
                      SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Échange en mains propres',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Choisissez un lieu de rencontre sécurisé',
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

                // Safety Tips
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16.0),
                  padding: EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.warningOrange.withAlpha(77),
                    ),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'security',
                        size: 20,
                        color: AppTheme.warningOrange,
                      ),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          'Privilégiez les lieux publics et fréquentés pour votre sécurité',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.warningOrange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 25.5),

                // Suggested Locations
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lieux suggérés',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 17.0),

                        // Location Options
                        ..._suggestedLocations.map((location) {
                          final isSelected =
                              _selectedLocation == location['id'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedLocation = location['id'];
                                _customLocationController.clear();
                              });
                              HapticFeedback.lightImpact();
                            },
                            child: Container(
                              margin: EdgeInsets.only(bottom: 17.0),
                              padding: EdgeInsets.all(16.0),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? location['color'].withAlpha(26)
                                    : colorScheme.surfaceContainerHighest
                                        .withAlpha(
                                        77,
                                      ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? location['color']
                                      : colorScheme.outline.withAlpha(77),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12.0),
                                    decoration: BoxDecoration(
                                      color: location['color'].withAlpha(26),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: CustomIconWidget(
                                      iconName: location['icon'],
                                      size: 24,
                                      color: location['color'],
                                    ),
                                  ),
                                  SizedBox(width: 12.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          location['name'],
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          location['description'],
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    CustomIconWidget(
                                      iconName: 'check_circle',
                                      size: 24,
                                      color: location['color'],
                                    ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),

                        SizedBox(height: 17.0),

                        // Custom Location Input
                        Text(
                          'Ou proposez un lieu',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 8.5),
                        TextField(
                          controller: _customLocationController,
                          decoration: InputDecoration(
                            hintText:
                                'Entrez une adresse ou lieu personnalisé...',
                            prefixIcon: CustomIconWidget(
                              iconName: 'edit_location',
                              color: AppTheme.textSecondary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colorScheme.outline.withAlpha(77),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryOrange,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                _selectedLocation = '';
                              });
                            }
                          },
                        ),
                        SizedBox(height: 34.0),
                      ],
                    ),
                  ),
                ),

                // Confirm Button
                Container(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_selectedLocation.isNotEmpty ||
                              _customLocationController.text.trim().isNotEmpty)
                          ? _confirmMeetingPoint
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryOrange,
                        padding: EdgeInsets.symmetric(vertical: 17.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirmer le lieu de rencontre',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
