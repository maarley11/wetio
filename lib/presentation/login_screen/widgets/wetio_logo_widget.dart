import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class WetioLogoWidget extends StatelessWidget {
  final double? size;

  const WetioLogoWidget({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // Make logo very large as requested - increase default size significantly
    final logoSize = size ?? 90.w; // Very large - 90% of screen width

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main Logo Container - Very large new logo
          Container(
            width: logoSize,
            height: logoSize * 0.4, // Better ratio for the new logo
            margin: EdgeInsets
                .zero, // Removed vertical margin to allow slogan to get closer
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/Wetio-1762471032439.png',
                width: logoSize,
                height: logoSize * 0.4,
                fit: BoxFit.contain, // Contain is safer than cover for logos
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('WETIO Logo loading error: $error');
                  
                  // Try falling back to the old logo just in case
                  return Image.asset(
                    'assets/images/logo_circle.png',
                    width: logoSize,
                    height: logoSize * 0.4,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                    width: logoSize,
                    height: logoSize * 0.4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colorScheme.primary, colorScheme.secondary],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withAlpha(77),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'WETIO',
                            style: GoogleFonts.inter(
                              fontSize: logoSize *
                                  0.12, // Large font for very large logo
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onPrimary,
                              letterSpacing: 3,
                            ),
                          ),
                          SizedBox(height: 4.3),
                          Text(
                            'Image en cours de chargement...',
                            style: GoogleFonts.inter(
                              fontSize: logoSize * 0.025,
                              fontWeight: FontWeight.w400,
                              color: colorScheme.onPrimary.withAlpha(204),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ); // closes Container
                }, // closes inner errorBuilder
              ); // closes inner Image.asset
            }, // closes outer errorBuilder
          ), // closes outer Image.asset
        ), // closes ClipRRect
      ), // closes outer Container
    ], // closes Column children
  ), // closes Column
); // closes Center
  }
}
