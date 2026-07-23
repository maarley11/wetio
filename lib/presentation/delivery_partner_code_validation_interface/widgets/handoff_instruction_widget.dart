import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class HandoffInstructionWidget extends StatelessWidget {
  final int currentStep;
  final String personAName;
  final String personBName;
  final String personAProduct;
  final String personBProduct;
  final String personAAddress;
  final String personBAddress;

  const HandoffInstructionWidget({
    super.key,
    required this.currentStep,
    required this.personAName,
    required this.personBName,
    required this.personAProduct,
    required this.personBProduct,
    required this.personAAddress,
    required this.personBAddress,
  });

  @override
  Widget build(BuildContext context) {
    final info = _getStepInfo();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(currentStep),
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              info.color.withValues(alpha: 0.08),
              info.color.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: info.color.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Icon(info.icon, color: info.color, size: 22),
                ),
                SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info.stepLabel,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: info.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        info.title,
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.8),
            Text(
              info.instruction,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 12.8),
            // Address chip
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.8),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: info.color,
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      info.address,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.8),
            // Action required
            Container(
              padding: EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: info.color,
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      info.actionRequired,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StepDetails _getStepInfo() {
    switch (currentStep) {
      case 0:
        return _StepDetails(
          stepLabel: 'ÉTAPE 1 SUR 3',
          title: 'Chez $personAName',
          instruction:
              'Rendez-vous à l\'adresse de $personAName pour récupérer « $personAProduct ».',
          actionRequired:
              'Demandez le code à $personAName et saisissez-le ci-dessous pour confirmer la récupération du produit.',
          address: personAAddress.isNotEmpty
              ? personAAddress
              : 'Adresse de $personAName',
          icon: Icons.directions_bike_outlined,
          color: AppTheme.primaryGreen,
        );
      case 1:
        return _StepDetails(
          stepLabel: 'ÉTAPE 2 SUR 3',
          title: 'Chez $personBName',
          instruction:
              'Rendez-vous chez $personBName. Remettez-lui « $personAProduct » puis récupérez « $personBProduct ».',
          actionRequired:
              'Après avoir remis le produit, demandez le code à $personBName et saisissez-le pour confirmer l\'échange.',
          address: personBAddress.isNotEmpty
              ? personBAddress
              : 'Adresse de $personBName',
          icon: Icons.swap_horiz,
          color: Colors.orange,
        );
      case 2:
        return _StepDetails(
          stepLabel: 'ÉTAPE 3 SUR 3',
          title: 'Retour chez $personAName',
          instruction:
              'Retournez chez $personAName et remettez-lui « $personBProduct » pour finaliser l\'échange.',
          actionRequired:
              '$personAName doit confirmer la réception dans l\'application. L\'échange sera alors terminé.',
          address: personAAddress.isNotEmpty
              ? personAAddress
              : 'Adresse de $personAName',
          icon: Icons.home_outlined,
          color: Colors.blue,
        );
      default:
        return _StepDetails(
          stepLabel: 'TERMINÉ',
          title: 'Échange terminé',
          instruction: 'Toutes les étapes ont été complétées avec succès.',
          actionRequired: 'Merci pour votre service !',
          address: '',
          icon: Icons.check_circle_outline,
          color: AppTheme.successGreen,
        );
    }
  }
}

class _StepDetails {
  final String stepLabel;
  final String title;
  final String instruction;
  final String actionRequired;
  final String address;
  final IconData icon;
  final Color color;

  const _StepDetails({
    required this.stepLabel,
    required this.title,
    required this.instruction,
    required this.actionRequired,
    required this.address,
    required this.icon,
    required this.color,
  });
}
