import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_theme.dart';

class VehicleInfoSection extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(Map<String, dynamic>) onDataChanged;

  const VehicleInfoSection({
    super.key,
    required this.formKey,
    required this.onDataChanged,
  });

  @override
  State<VehicleInfoSection> createState() => _VehicleInfoSectionState();
}

class _VehicleInfoSectionState extends State<VehicleInfoSection> {
  String _selectedVehicleType = '';
  final _licenseController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _insuranceController = TextEditingController();
  XFile? _vehiclePhoto;
  XFile? _licensePhoto;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {
      'id': 'bike',
      'name': 'Vélo',
      'icon': Icons.pedal_bike,
      'description': 'Idéal pour les courtes distances',
    },
    {
      'id': 'motorcycle',
      'name': 'Moto',
      'icon': Icons.two_wheeler,
      'description': 'Parfait pour la ville',
    },
    {
      'id': 'car',
      'name': 'Voiture',
      'icon': Icons.directions_car,
      'description': 'Pour les gros volumes',
    },
  ];

  @override
  void initState() {
    super.initState();
    _licenseController.addListener(_updateData);
    _vehicleModelController.addListener(_updateData);
    _plateNumberController.addListener(_updateData);
    _insuranceController.addListener(_updateData);
  }

  void _updateData() {
    widget.onDataChanged({
      'vehicleType': _selectedVehicleType,
      'licenseNumber': _licenseController.text,
      'vehicleModel': _vehicleModelController.text,
      'plateNumber': _plateNumberController.text,
      'insuranceNumber': _insuranceController.text,
      'vehiclePhoto': _vehiclePhoto,
      'licensePhoto': _licensePhoto,
    });
  }

  Future<void> _pickVehiclePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _vehiclePhoto = image;
      });
      _updateData();
    }
  }

  Future<void> _pickLicensePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _licensePhoto = image;
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
            // Vehicle type selection
            Text(
              'Type de véhicule *',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            ...List.generate(_vehicleTypes.length, (index) {
              final vehicle = _vehicleTypes[index];
              final isSelected = _selectedVehicleType == vehicle['id'];

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedVehicleType = vehicle['id'];
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
                          vehicle['icon'],
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
                                vehicle['name'],
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? AppTheme.primaryGreen
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                vehicle['description'],
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

            // License information
            Text(
              'Informations du permis',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _licenseController,
              decoration: const InputDecoration(
                labelText: 'Numéro de permis *',
                hintText: 'Entrez votre numéro de permis',
                prefixIcon: Icon(Icons.credit_card),
              ),
              validator: (value) {
                if (_selectedVehicleType != 'bike' &&
                    (value == null || value.isEmpty)) {
                  return 'Le numéro de permis est requis';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            // License photo
            Text(
              'Photo du permis ${_selectedVehicleType != 'bike' ? '*' : '(optionnel)'}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            GestureDetector(
              onTap: _pickLicensePhoto,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.borderLight.withValues(alpha: 0.1),
                ),
                child: _licensePhoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1614624532983-4ce03382d63d?w=400&h=300&fit=crop',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image,
                                size: 40,
                                color: AppTheme.textSecondary,
                              ),
                            );
                          },
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Prendre une photo du permis',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Vehicle information
            Text(
              'Informations du véhicule',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _vehicleModelController,
              decoration: const InputDecoration(
                labelText: 'Modèle du véhicule *',
                hintText: 'Ex: Yamaha MT-125, Toyota Corolla',
                prefixIcon: Icon(Icons.directions_car),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Le modèle du véhicule est requis';
                }
                return null;
              },
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 16),

            if (_selectedVehicleType != 'bike') ...[
              TextFormField(
                controller: _plateNumberController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de plaque *',
                  hintText: 'Ex: AB 123 CD',
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le numéro de plaque est requis';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _insuranceController,
                decoration: const InputDecoration(
                  labelText: 'Numéro d\'assurance *',
                  hintText: 'Numéro de police d\'assurance',
                  prefixIcon: Icon(Icons.security),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Le numéro d\'assurance est requis';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
            ],

            // Vehicle photo
            Text(
              'Photo du véhicule *',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            GestureDetector(
              onTap: _pickVehiclePhoto,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.borderLight),
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.borderLight.withValues(alpha: 0.1),
                ),
                child: _vehiclePhoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.network(
                          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=300&fit=crop',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.image,
                                size: 40,
                                color: AppTheme.textSecondary,
                              ),
                            );
                          },
                        ),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: AppTheme.textSecondary,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Prendre une photo du véhicule',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _vehicleModelController.dispose();
    _plateNumberController.dispose();
    _insuranceController.dispose();
    super.dispose();
  }
}
