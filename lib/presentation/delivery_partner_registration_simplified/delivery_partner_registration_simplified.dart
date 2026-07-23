import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/benefits_step.dart';
import './widgets/payment_step.dart';
import './widgets/personal_info_step.dart';

class DeliveryPartnerRegistrationSimplified extends StatefulWidget {
  const DeliveryPartnerRegistrationSimplified({super.key});

  @override
  State<DeliveryPartnerRegistrationSimplified> createState() =>
      _DeliveryPartnerRegistrationSimplifiedState();
}

class _DeliveryPartnerRegistrationSimplifiedState
    extends State<DeliveryPartnerRegistrationSimplified>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _currentStep = 0;
  final int _totalSteps = 3;

  final _formData = <String, dynamic>{
    'firstName': '',
    'lastName': '',
    'phone': '',
    'email': '',
    'profilePhoto': null,
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    } else {
      Navigator.pop(context);
    }
  }

  void _updateFormData(String key, dynamic value) {
    setState(() => _formData[key] = value);
  }

  void _completeRegistration() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppTheme.successGreen.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 48.0,
                color: AppTheme.successGreen,
              ),
            ),
            SizedBox(height: 17.0),
            Text(
              'Inscription réussie !',
              style: GoogleFonts.dmSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.8),
            Text(
              'Votre compte livreur est maintenant actif. Vous recevrez une notification dès qu\'une demande de livraison sera faite près de chez vous.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 25.5),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRoutes.homeFeed,
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  padding: EdgeInsets.symmetric(vertical: 15.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Retour à l\'accueil',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          _previousStep();
          return false;
        }
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          elevation: 0,
          leading: _currentStep > 0
              ? IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    color: colorScheme.onSurface,
                  ),
                  onPressed: () {
                    _previousStep();
                  },
                )
              : const SizedBox.shrink(),
          automaticallyImplyLeading: false,
          title: Text(
            'Devenir Livreur',
            style: GoogleFonts.dmSans(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 4.3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentStep + 1}/$_totalSteps',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              Container(
                height: 4,
                margin: EdgeInsets.symmetric(horizontal: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    backgroundColor: colorScheme.outline.withValues(
                      alpha: 0.15,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryGreen,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.5),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    _buildStepLabel(context, 0, 'Infos', Icons.person_outline),
                    Expanded(
                      child: Divider(
                        color: _currentStep > 0
                            ? AppTheme.primaryGreen
                            : colorScheme.outline.withValues(alpha: 0.3),
                        thickness: 1.5,
                      ),
                    ),
                    _buildStepLabel(
                      context,
                      1,
                      'Avantages',
                      Icons.star_outline,
                    ),
                    Expanded(
                      child: Divider(
                        color: _currentStep > 1
                            ? AppTheme.primaryGreen
                            : colorScheme.outline.withValues(alpha: 0.3),
                        thickness: 1.5,
                      ),
                    ),
                    _buildStepLabel(
                      context,
                      2,
                      'Paiement',
                      Icons.payment_outlined,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8.5),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    PersonalInfoStep(
                      formData: _formData,
                      onUpdateData: _updateFormData,
                      onNext: _nextStep,
                    ),
                    BenefitsStep(onNext: _nextStep, onPrevious: _previousStep),
                    PaymentStep(
                      onComplete: _completeRegistration,
                      onPrevious: _previousStep,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepLabel(
    BuildContext context,
    int step,
    String label,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCompleted = _currentStep > step;
    final isActive = _currentStep == step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: isCompleted
                ? AppTheme.primaryGreen
                : isActive
                    ? colorScheme.primaryContainer
                    : colorScheme.outline.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppTheme.primaryGreen : Colors.transparent,
              width: 2,
            ),
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            size: 16.0,
            color: isCompleted
                ? Colors.white
                : isActive
                    ? AppTheme.primaryGreen
                    : colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 3.4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color:
                isActive ? AppTheme.primaryGreen : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
