import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/banking_info_section.dart';
import './widgets/document_upload_section.dart';
import './widgets/personal_info_section.dart';
import './widgets/service_preferences_section.dart';
import './widgets/terms_section.dart';
import './widgets/vehicle_info_section.dart';

class DeliveryPartnerRegistration extends StatefulWidget {
  const DeliveryPartnerRegistration({super.key});

  @override
  State<DeliveryPartnerRegistration> createState() =>
      _DeliveryPartnerRegistrationState();
}

class _DeliveryPartnerRegistrationState
    extends State<DeliveryPartnerRegistration> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 6;
  bool _isLoading = false;

  // Form controllers
  final _personalFormKey = GlobalKey<FormState>();
  final _vehicleFormKey = GlobalKey<FormState>();
  final _serviceFormKey = GlobalKey<FormState>();
  final _documentFormKey = GlobalKey<FormState>();
  final _bankingFormKey = GlobalKey<FormState>();
  final _termsFormKey = GlobalKey<FormState>();

  // Form data
  Map<String, dynamic> _formData = {
    'personal': {},
    'vehicle': {},
    'service': {},
    'documents': {},
    'banking': {},
    'terms': {},
  };

  final List<String> _stepTitles = [
    'Informations personnelles',
    'Véhicule et Documents',
    'Préférences de service',
    'Téléchargement de documents',
    'Informations bancaires',
    'Conditions générales',
  ];

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _submitForm();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _personalFormKey.currentState?.validate() ?? false;
      case 1:
        return _vehicleFormKey.currentState?.validate() ?? false;
      case 2:
        return _serviceFormKey.currentState?.validate() ?? false;
      case 3:
        return _documentFormKey.currentState?.validate() ?? false;
      case 4:
        return _bankingFormKey.currentState?.validate() ?? false;
      case 5:
        return _termsFormKey.currentState?.validate() ?? false;
      default:
        return false;
    }
  }

  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Inscription soumise avec succès! Nous vous contacterons sous 48h.'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'inscription. Veuillez réessayer.'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: Text(
          'Inscription Livreur',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Étape ${_currentStep + 1} sur $_totalSteps',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${(((_currentStep + 1) / _totalSteps) * 100).round()}%',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    backgroundColor: AppTheme.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primaryGreen),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _stepTitles[_currentStep],
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                PersonalInfoSection(
                  formKey: _personalFormKey,
                  onDataChanged: (data) {
                    _formData['personal'] = data;
                  },
                ),
                VehicleInfoSection(
                  formKey: _vehicleFormKey,
                  onDataChanged: (data) {
                    _formData['vehicle'] = data;
                  },
                ),
                ServicePreferencesSection(
                  formKey: _serviceFormKey,
                  onDataChanged: (data) {
                    _formData['service'] = data;
                  },
                ),
                DocumentUploadSection(
                  formKey: _documentFormKey,
                  onDataChanged: (data) {
                    _formData['documents'] = data;
                  },
                ),
                BankingInfoSection(
                  formKey: _bankingFormKey,
                  onDataChanged: (data) {
                    _formData['banking'] = data;
                  },
                ),
                TermsSection(
                  formKey: _termsFormKey,
                  onDataChanged: (data) {
                    _formData['terms'] = data;
                  },
                ),
              ],
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceWhite,
              border: Border(
                top: BorderSide(color: AppTheme.borderLight, width: 1),
              ),
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _previousStep,
                      child: Text(
                        'Précédent',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.surfaceWhite),
                            ),
                          )
                        : Text(
                            _currentStep == _totalSteps - 1
                                ? 'Soumettre'
                                : 'Suivant',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
