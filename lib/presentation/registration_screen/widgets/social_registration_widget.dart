import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SocialRegistrationWidget extends StatelessWidget {
  final VoidCallback onGoogleSignUp;
  final VoidCallback onAppleSignUp;
  final bool isLoading;

  const SocialRegistrationWidget({
    super.key,
    required this.onGoogleSignUp,
    required this.onAppleSignUp,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Divider with "OU" text
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'OU',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),

        SizedBox(height: 25.5),

        // Social buttons title
        Text(
          'Inscription rapide avec',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 17.0),

        // Social buttons
        Row(
          children: [
            // Google Sign Up Button
            Expanded(
              child: _buildSocialButton(
                context: context,
                onTap: isLoading
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onGoogleSignUp();
                      },
                iconName: 'google',
                label: 'Google',
                backgroundColor: Colors.white,
                borderColor: colorScheme.outline,
                textColor: Colors.black87,
                iconColor: null, // Use original Google colors
              ),
            ),

            SizedBox(width: 12.0),

            // Apple Sign Up Button
            Expanded(
              child: _buildSocialButton(
                context: context,
                onTap: isLoading
                    ? null
                    : () {
                        HapticFeedback.lightImpact();
                        onAppleSignUp();
                      },
                iconName: 'apple',
                label: 'Apple',
                backgroundColor: Colors.black,
                borderColor: Colors.black,
                textColor: Colors.white,
                iconColor: Colors.white,
              ),
            ),
          ],
        ),

        SizedBox(height: 17.0),

        // Info text
        Text(
          'En vous inscrivant via les réseaux sociaux, vous acceptez automatiquement nos conditions d\'utilisation.',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required VoidCallback? onTap,
    required String iconName,
    required String label,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42.5,
        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.5),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: borderColor, width: 1),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconName == 'google'
                ? SvgPicture.asset('assets/images/google_logo.svg', width: 18, height: 18)
                : CustomIconWidget(iconName: iconName, size: 18, color: iconColor),
            SizedBox(width: 8.0),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
