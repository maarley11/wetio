import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class ServicePreferencesSection extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(Map<String, dynamic>) onDataChanged;

  const ServicePreferencesSection({
    super.key,
    required this.formKey,
    required this.onDataChanged,
  });

  @override
  State<ServicePreferencesSection> createState() =>
      _ServicePreferencesSectionState();
}

class _ServicePreferencesSectionState extends State<ServicePreferencesSection> {
  List<String> _selectedDays = [];
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 18, minute: 0);
  List<String> _selectedDeliveryTypes = [];
  double _maxDistance = 10.0;
  List<String> _selectedZones = [];

  final List<Map<String, String>> _weekDays = [
    {'id': 'monday', 'name': 'Lundi'},
    {'id': 'tuesday', 'name': 'Mardi'},
    {'id': 'wednesday', 'name': 'Mercredi'},
    {'id': 'thursday', 'name': 'Jeudi'},
    {'id': 'friday', 'name': 'Vendredi'},
    {'id': 'saturday', 'name': 'Samedi'},
    {'id': 'sunday', 'name': 'Dimanche'},
  ];

  final List<Map<String, dynamic>> _deliveryTypes = [
    {
      'id': 'food',
      'name': 'Nourriture',
      'icon': Icons.restaurant,
      'description': 'Livraison de repas et boissons',
    },
    {
      'id': 'packages',
      'name': 'Colis',
      'icon': Icons.inventory_2,
      'description': 'Livraison de produits et packages',
    },
    {
      'id': 'documents',
      'name': 'Documents',
      'icon': Icons.description,
      'description': 'Livraison de documents urgents',
    },
    {
      'id': 'pharmacy',
      'name': 'Pharmacie',
      'icon': Icons.local_pharmacy,
      'description': 'Livraison de médicaments',
    },
  ];

  final List<String> _zones = [
    'Abidjan - Cocody',
    'Abidjan - Plateau',
    'Abidjan - Marcory',
    'Abidjan - Adjamé',
    'Abidjan - Yopougon',
    'Abidjan - Koumassi',
    'Abidjan - Port-Bouët',
    'Abidjan - Treichville',
    'Abidjan - Abobo',
    'Abidjan - Attécoubé',
  ];

  @override
  void initState() {
    super.initState();
    _updateData();
  }

  void _updateData() {
    widget.onDataChanged({
      'availableDays': _selectedDays,
      'startTime': _startTime,
      'endTime': _endTime,
      'deliveryTypes': _selectedDeliveryTypes,
      'maxDistance': _maxDistance,
      'coverageZones': _selectedZones,
    });
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryGreen,
              onPrimary: AppTheme.surfaceWhite,
              surface: AppTheme.surfaceWhite,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
      _updateData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Availability section
            Text(
              'Disponibilité',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Text(
              'Jours de travail',
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
              children: _weekDays.map((day) {
                final isSelected = _selectedDays.contains(day['id']);
                return FilterChip(
                  label: Text(day['name']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedDays.add(day['id']!);
                      } else {
                        _selectedDays.remove(day['id']!);
                      }
                    });
                    _updateData();
                  },
                  backgroundColor: AppTheme.surfaceWhite,
                  selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                  checkmarkColor: AppTheme.primaryGreen,
                  side: BorderSide(
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : AppTheme.borderLight,
                  ),
                  labelStyle: GoogleFonts.inter(
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Time availability
            Text(
              'Heures de disponibilité',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(context, true),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Début',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _startTime.format(context),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectTime(context, false),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.borderLight),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fin',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _endTime.format(context),
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Delivery types
            Text(
              'Types de livraison',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            ...List.generate(_deliveryTypes.length, (index) {
              final deliveryType = _deliveryTypes[index];
              final isSelected =
                  _selectedDeliveryTypes.contains(deliveryType['id']);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedDeliveryTypes.remove(deliveryType['id']);
                      } else {
                        _selectedDeliveryTypes.add(deliveryType['id']);
                      }
                    });
                    _updateData();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : AppTheme.borderLight,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected
                          ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                          : AppTheme.surfaceWhite,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          deliveryType['icon'],
                          color: isSelected
                              ? AppTheme.primaryGreen
                              : AppTheme.textSecondary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                deliveryType['name'],
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppTheme.primaryGreen
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                deliveryType['description'],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryGreen,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // Max distance
            Text(
              'Distance maximale de livraison',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              '${_maxDistance.round()} km',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),

            Slider(
              value: _maxDistance,
              min: 1.0,
              max: 50.0,
              divisions: 49,
              activeColor: AppTheme.primaryGreen,
              inactiveColor: AppTheme.borderLight,
              onChanged: (value) {
                setState(() {
                  _maxDistance = value;
                });
                _updateData();
              },
            ),

            const SizedBox(height: 24),

            // Coverage zones
            Text(
              'Zones de couverture',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.borderLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: _zones.map((zone) {
                  final isSelected = _selectedZones.contains(zone);
                  return CheckboxListTile(
                    title: Text(
                      zone,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedZones.add(zone);
                        } else {
                          _selectedZones.remove(zone);
                        }
                      });
                      _updateData();
                    },
                    activeColor: AppTheme.primaryGreen,
                    controlAffinity: ListTileControlAffinity.trailing,
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
