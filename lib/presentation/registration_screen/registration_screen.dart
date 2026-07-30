import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../login_screen/widgets/wetio_logo_widget.dart';
import './widgets/location_section_widget.dart';
import './widgets/profile_photo_section_widget.dart';
import './widgets/registration_form_widget.dart';
import './widgets/social_registration_widget.dart';
import './widgets/terms_agreement_widget.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool _isLoading = false;
  String? _profileImagePath;
  String _selectedLocation = '';
  bool _termsAccepted = false;
  bool _isFormValid = false;

  // Form controllers
  final _fullNameController = TextEditingController();
  final _pseudoController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Listen to form changes
    _fullNameController.addListener(_updateFormValidity);
    _pseudoController.addListener(_updateFormValidity);
    _emailController.addListener(_updateFormValidity);
    _phoneController.addListener(_updateFormValidity);
    _passwordController.addListener(_updateFormValidity);
    _confirmPasswordController.addListener(_updateFormValidity);
  }

  void _updateFormValidity() {
    final hasIdentifier =
        _phoneController.text.isNotEmpty || _emailController.text.isNotEmpty;

    final isValid = _fullNameController.text.isNotEmpty &&
        _pseudoController.text.isNotEmpty &&
        hasIdentifier &&
        _passwordController.text.isNotEmpty &&
        _confirmPasswordController.text.isNotEmpty &&
        _passwordController.text.length >= 6;

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _pseudoController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration({
    required String fullName,
    required String pseudo,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    if (!_termsAccepted) {
      _showErrorMessage('Veuillez accepter les conditions d\'utilisation');
      return;
    }

    if (password != confirmPassword) {
      _showErrorMessage('Les mots de passe ne correspondent pas');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bool usePhone = phone.isNotEmpty && email.isEmpty;

      if (usePhone) {
        // Phone-only registration: create account with phone as identifier
        // We use a generated email from phone for Supabase auth
        final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
        final generatedEmail =
            'phone_${cleanPhone.replaceAll('+', '')}@wetio.app';

        final response = await SupabaseService.signUpWithEmail(
          email: generatedEmail,
          password: password,
          fullName: fullName,
          pseudo: pseudo,
          phone: cleanPhone,
          location: _selectedLocation,
        );

        if (response.user != null) {
          HapticFeedback.mediumImpact();
          // If session is active, user is already logged in — go directly to home
          if (response.session != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Compte créé avec succès! Bienvenue sur WETIO 🎉',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                backgroundColor: AppTheme.successGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.homeFeed,
                (route) => false,
              );
            }
          } else {
            _showPhoneSuccessDialog(phone: phone, userId: response.user!.id);
          }
        } else {
          _showErrorMessage('Erreur lors de la création du compte');
        }
      } else {
        // Email registration
        final response = await SupabaseService.signUpWithEmail(
          email: email,
          password: password,
          fullName: fullName,
          pseudo: pseudo,
          phone: phone,
          location: _selectedLocation,
        );

        if (response.user != null) {
          HapticFeedback.mediumImpact();
          // If session is active, user is already logged in — go directly to home
          if (response.session != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Compte créé avec succès! Bienvenue sur WETIO 🎉',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                backgroundColor: AppTheme.successGreen,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.homeFeed,
                (route) => false,
              );
            }
          } else {
            _showSuccessDialog(email: email, userId: response.user!.id);
          }
        } else {
          _showErrorMessage('Erreur lors de la création du compte');
        }
      }
    } catch (e) {
      String errorMessage = 'Erreur lors de l\'inscription';

      if (e.toString().contains('User already registered')) {
        errorMessage = 'Ce compte existe déjà. Essayez de vous connecter.';
      } else if (e.toString().contains(
            'duplicate key value violates unique constraint "unique_pseudo"',
          )) {
        errorMessage = 'Ce pseudo est déjà utilisé, choisissez-en un autre';
      } else if (e.toString().contains(
            'Password should be at least 6 characters',
          )) {
        errorMessage = 'Le mot de passe doit contenir au moins 6 caractères';
      } else if (e.toString().contains('Invalid email')) {
        errorMessage = 'Format d\'email invalide';
      } else if (e.toString().contains(
            'duplicate key value violates unique constraint "user_profiles_email_key"',
          )) {
        errorMessage = 'Cette adresse email est déjà utilisée';
      } else if (e.toString().contains('phone')) {
        errorMessage = 'Ce numéro de téléphone est déjà utilisé';
      }

      _showErrorMessage(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showPhoneSuccessDialog({
    required String phone,
    required String userId,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successGreen, size: 28),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Inscription réussie!',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📱 Compte créé avec succès!',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 17.0),
              Text(
                'Votre compte a été créé avec le numéro:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8.5),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.5),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  phone,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(height: 17.0),
              Text(
                'Vous pouvez maintenant vous connecter avec votre numéro de téléphone et votre mot de passe.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(); // Return to login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Se connecter',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog({required String email, required String userId}) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.successGreen, size: 28),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Inscription réussie!',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📧 Vérifiez votre email',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 17.0),
              Text(
                'Un email de confirmation a été envoyé à:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 8.5),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.5),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(height: 17.0),
              Text(
                '⚠️ Important:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.error,
                ),
              ),
              SizedBox(height: 8.5),
              Text(
                '1. Cliquez sur le lien de confirmation dans l\'email\n'
                '2. Vérifiez vos spams si vous ne le voyez pas\n'
                '3. Une fois confirmé, vous pourrez vous connecter',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Resend confirmation email
                try {
                  await SupabaseService.resendConfirmationEmail(email);

                  if (mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Email de confirmation renvoyé!',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                        backgroundColor: AppTheme.successGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Erreur lors du renvoi de l\'email',
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                        backgroundColor: colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Renvoyer l\'email',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(); // Return to login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Compris',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleRegistrationWrapper() {
    _handleRegistration(
      fullName: _fullNameController.text.trim(),
      pseudo: _pseudoController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
  }

  void _showErrorMessage(String message) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: AppTheme.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleGoogleSignUp() async {
  void _showProviderPendingDialog(String providerName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppTheme.primaryGreen, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Inscription $providerName',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'L\'inscription par $providerName nécessite la configuration des identifiants OAuth ($providerName Cloud / Apple Developer) sur la console Supabase.\n\n'
          'Veuillez utiliser votre numéro de téléphone ou votre adresse email pour vous inscrire.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Compris', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _handleGoogleSignUp() async {
    try {
      await SupabaseService.signInWithGoogle();
    } catch (e) {
      if (mounted) _showProviderPendingDialog('Google');
    }
  }

  void _handleAppleSignUp() async {
    try {
      await SupabaseService.signInWithApple();
    } catch (e) {
      if (mounted) _showProviderPendingDialog('Apple');
    }
  }

  void _handleFacebookSignUp() {
    _showComingSoonMessage('Facebook');
  }

  void _showComingSoonMessage(String platform) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Inscription $platform bientôt disponible',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        backgroundColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onPhotoSelected(String imagePath) {
    setState(() {
      _profileImagePath = imagePath;
    });
  }

  void _onLocationSelected(String location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  void _onTermsAcceptanceChanged(bool accepted) {
    setState(() {
      _termsAccepted = accepted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: colorScheme.onSurface,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Créer un compte',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 17.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo Section - Very large at top
                Center(
                  child: WetioLogoWidget(
                    size: 90.w, // Very large as requested
                  ),
                ),

                SizedBox(height: 25.5),

                // Welcome Text
                Text(
                  'Rejoignez WETIO',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.5),

                Text(
                  'Créez votre compte pour commencer à échanger',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 34.0),

                // Profile Photo Section
                ProfilePhotoSectionWidget(
                  onPhotoSelected: _onPhotoSelected,
                  isLoading: _isLoading,
                ),

                SizedBox(height: 25.5),

                // Registration Form
                RegistrationFormWidget(
                  fullNameController: _fullNameController,
                  pseudoController: _pseudoController,
                  emailController: _emailController,
                  phoneController: _phoneController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  onRegister: _handleRegistration,
                  isLoading: _isLoading,
                ),

                SizedBox(height: 25.5),

                // Location Section
                LocationSectionWidget(
                  onLocationSelected: _onLocationSelected,
                  isLoading: _isLoading,
                ),

                SizedBox(height: 25.5),

                // Terms Agreement with Registration Button
                TermsAgreementWidget(
                  isAccepted: _termsAccepted,
                  onChanged: _onTermsAcceptanceChanged,
                  isLoading: _isLoading,
                  onRegister: _handleRegistrationWrapper,
                  isFormValid: _isFormValid,
                ),

                SizedBox(height: 34.0),

                // Social Registration
                SocialRegistrationWidget(
                  onGoogleSignUp: _handleGoogleSignUp,
                  onAppleSignUp: _handleAppleSignUp,
                  isLoading: _isLoading,
                ),

                SizedBox(height: 34.0),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Déjà un compte? ',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    GestureDetector(
                      onTap: _isLoading
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              Navigator.pop(context);
                            },
                      child: Text(
                        'Se connecter',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 17.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
