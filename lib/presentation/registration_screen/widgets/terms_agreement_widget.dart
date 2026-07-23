import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_routes.dart';

class TermsAgreementWidget extends StatelessWidget {
  final bool isAccepted;
  final Function(bool) onChanged;
  final bool isLoading;
  final VoidCallback? onRegister;
  final bool isFormValid;

  const TermsAgreementWidget({
    super.key,
    required this.isAccepted,
    required this.onChanged,
    this.isLoading = false,
    this.onRegister,
    this.isFormValid = false,
  });

  void _navigateToTermsScreen(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.termsOfServiceScreen);
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.5),
        Text(
          content,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        SizedBox(height: 17.0),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: isAccepted
              ? colorScheme.primary.withValues(alpha: 0.3)
              : colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isAccepted
            ? colorScheme.primary.withValues(alpha: 0.05)
            : colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.security,
                color: colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 8.0),
              Text(
                'Conditions d\'utilisation',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),

          SizedBox(height: 17.0),

          // Checkbox and agreement text
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: isLoading
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onChanged(!isAccepted);
                      },
                child: Container(
                  width: 20,
                  height: 20,
                  margin: EdgeInsets.only(top: 1.7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isAccepted
                          ? colorScheme.primary
                          : colorScheme.outline,
                      width: 2,
                    ),
                    color:
                        isAccepted ? colorScheme.primary : Colors.transparent,
                  ),
                  child: isAccepted
                      ? Icon(
                          Icons.check,
                          size: 14,
                          color: colorScheme.onPrimary,
                        )
                      : null,
                ),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: colorScheme.onSurface,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'J\'accepte les '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () => _navigateToTermsScreen(context),
                              child: Text(
                                'conditions d\'utilisation et politique de confidentialité de WETIO',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                  decorationColor: colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    if (!isAccepted) ...[
                      SizedBox(height: 8.5),
                      Text(
                        'Vous devez accepter les conditions pour créer votre compte.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: colorScheme.error,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 25.5),

          // Registration Button - MOVED HERE
          SizedBox(
            width: double.infinity,
            height: 51.0,
            child: ElevatedButton(
              onPressed:
                  isFormValid && isAccepted && !isLoading ? onRegister : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFormValid && isAccepted && !isLoading
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                foregroundColor: isFormValid && isAccepted && !isLoading
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                elevation: isFormValid && isAccepted && !isLoading ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.8),
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Text(
                      'Créer mon compte',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
