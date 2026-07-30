import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import './widgets/login_form_widget.dart';
import './widgets/social_login_widget.dart';
import './widgets/wetio_logo_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final FocusNode _identifierFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void dispose() {
    _identifierFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleLogin(String identifier, String password) async {
    setState(() {
      _isLoading = true;
    });

    try {
      print(
        '🚀 Début de la connexion avec: ${identifier.replaceAll(RegExp(r'[0-9]'), '*')}',
      );

      // Use Supabase authentication with email OR phone support
      final response = await SupabaseService.signInWithEmailOrPhone(
        identifier: identifier,
        password: password,
      );

      print('✅ Réponse d\'authentification reçue');

      if (response.user != null) {
        print('✅ Utilisateur connecté avec succès: ${response.user!.email}');

        HapticFeedback.mediumImpact();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Connexion réussie! Bienvenue sur WETIO',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
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
        }
      }
    } catch (e) {
      print('❌ Erreur lors de la connexion: $e');

      String errorString = e.toString();

      // Handle EMAIL_NOT_CONFIRMED with specific dialog
      if (errorString.contains('EMAIL_NOT_CONFIRMED')) {
        if (mounted) {
          _showEmailConfirmationDialog(identifier);
        }
        return; // Don't show generic error message
      }

      // Handle other specific errors
      String errorMessage = 'Erreur de connexion. Veuillez réessayer.';

      if (errorString.contains('PHONE_NOT_FOUND')) {
        errorMessage =
            'Aucun compte trouvé avec ce numéro de téléphone. Créez un compte.';
      } else if (errorString.contains('INVALID_CREDENTIALS')) {
        errorMessage = 'Email/téléphone ou mot de passe incorrect.';
      } else if (errorString.contains('PROFILE_INCOMPLETE')) {
        errorMessage = 'Profil incomplet. Contactez le support.';
      } else if (errorString.contains('ACCOUNT_INACTIVE')) {
        errorMessage = 'Votre compte a été désactivé. Contactez le support.';
      } else if (errorString.contains('TOO_MANY_REQUESTS')) {
        errorMessage = 'Trop de tentatives. Réessayez dans quelques minutes.';
      } else if (errorString.contains('DATABASE_ERROR')) {
        errorMessage = errorString;
      }

      if (mounted) {
        _showErrorMessage(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEmailConfirmationDialog(String identifier) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.email, color: colorScheme.primary, size: 28),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  'Email non confirmé',
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
                'Votre email n\'a pas encore été confirmé.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 17.0),
              Text(
                '📧 Pour vous connecter:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8.5),
              Text(
                '1. Vérifiez votre boîte email\n'
                '2. Cherchez l\'email de confirmation WETIO\n'
                '3. Cliquez sur le lien de confirmation\n'
                '4. Revenez ici pour vous connecter',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 17.0),
              Text(
                '💡 Astuce: Vérifiez vos spams',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Extract email from identifier
                String email = identifier;

                // If identifier looks like phone, we can't resend
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(identifier)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Impossible de renvoyer: utilisez votre email pour vous connecter',
                        style: GoogleFonts.inter(fontSize: 13),
                      ),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                  return;
                }

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
                          'Erreur lors du renvoi',
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
              onPressed: () => Navigator.of(dialogContext).pop(),
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
        action: message.contains('créez un compte')
            ? SnackBarAction(
                label: 'S\'inscrire',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.registrationScreen);
                },
              )
            : null,
      ),
    );
  }

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
                'Connexion $providerName',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'L\'authentification par $providerName nécessite la configuration des identifiants OAuth ($providerName Cloud / Apple Developer) sur la console Supabase.\n\n'
          'Veuillez utiliser votre numéro de téléphone ou votre adresse email pour vous connecter.',
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

  void _handleGoogleLogin() {
    _showProviderPendingDialog('Google');
  }

  void _handleAppleLogin() {
    _showProviderPendingDialog('Apple');
  }

  void _navigateToSignUp() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, AppRoutes.registrationScreen);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            // Dismiss keyboard when tapping outside
            FocusScope.of(context).unfocus();
          },
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 17.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 500,
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top spacing
                    SizedBox(height: 34.0),

                    // Logo Section with overlaid slogan - Significantly increased size
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          // Logo widget
                          WetioLogoWidget(
                            size: 120.w, // Significantly larger logo
                          ),

                          // Slogan positioned at bottom of logo - overlapping
                          Positioned(
                            bottom: 0.5
                                .h, // Very close to bottom edge - adjust as needed for perfect positioning
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(
                                  230,
                                ), // Semi-transparent white background for readability
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'kay Echanger ko',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 34.0),

                    // Welcome Text
                    Text(
                      'Bon retour!',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 8.5),

                    Text(
                      'Connectez-vous avec votre email ou téléphone',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    SizedBox(height: 34.0),

                    // Login Form
                    LoginFormWidget(
                      onLogin: _handleLogin,
                      isLoading: _isLoading,
                    ),

                    SizedBox(height: 34.0),

                    // Social Login Options
                    SocialLoginWidget(
                      onGoogleLogin: _handleGoogleLogin,
                      onAppleLogin: _handleAppleLogin,
                      isLoading: _isLoading,
                    ),

                    // Spacer to push sign up link to bottom
                    const Spacer(),

                    SizedBox(height: 34.0),

                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Nouveau? ',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        GestureDetector(
                          onTap: _isLoading ? null : _navigateToSignUp,
                          child: Text(
                            'S\'inscrire',
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
          ),
        ),
      ),
    );
  }
}
