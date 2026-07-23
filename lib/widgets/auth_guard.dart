import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../services/supabase_service.dart';

/// Checks if the user is authenticated.
/// If yes, runs [onAuthenticated].
/// If no, shows a bottom sheet asking to login or register.
void requireAuth(BuildContext context, VoidCallback onAuthenticated) {
  final client = SupabaseService.safeClient;
  final isLoggedIn = client?.auth.currentUser != null;

  if (isLoggedIn) {
    onAuthenticated();
  } else {
    _showAuthBottomSheet(context, onAuthenticated);
  }
}

void _showAuthBottomSheet(BuildContext context, VoidCallback onAuthenticated) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AuthBottomSheet(onAuthenticated: onAuthenticated),
  );
}

class _AuthBottomSheet extends StatelessWidget {
  final VoidCallback onAuthenticated;

  const _AuthBottomSheet({required this.onAuthenticated});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20.0, 17.0, 20.0, 34.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40.0,
            height: 4.3,
            decoration: BoxDecoration(
              color: colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          SizedBox(height: 21.3),

          // Icon
          Container(
            padding: EdgeInsets.all(14.0),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.primaryOrange,
              size: 28.0,
            ),
          ),
          SizedBox(height: 17.0),

          // Title
          Text(
            'Connexion requise',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 8.5),

          // Subtitle
          Text(
            'Pour effectuer cette action, vous devez\nvous connecter ou créer un compte.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          SizedBox(height: 25.5),

          // Se connecter button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.loginScreen,
                ).then((_) {
                  // After returning from login, check if now authenticated
                  final client = SupabaseService.safeClient;
                  if (client?.auth.currentUser != null) {
                    onAuthenticated();
                  }
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 15.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Se connecter',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.8),

          // S'inscrire button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.registrationScreen,
                ).then((_) {
                  final client = SupabaseService.safeClient;
                  if (client?.auth.currentUser != null) {
                    onAuthenticated();
                  }
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryOrange,
                side: BorderSide(
                  color: AppTheme.primaryOrange.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                padding: EdgeInsets.symmetric(vertical: 15.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Créer un compte',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryOrange,
                ),
              ),
            ),
          ),
          SizedBox(height: 8.5),

          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
