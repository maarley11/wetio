import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class StepDetailCardWidget extends StatelessWidget {
  final int currentStep;
  final String personAName;
  final String personBName;
  final String personAProduct;
  final String personBProduct;
  final String personAAddress;
  final String personBAddress;

  const StepDetailCardWidget({
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
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(),
          SizedBox(height: 12.8),
          ..._buildStepInstructions(),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    final stepData = _getStepData();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (stepData['color'] as Color).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Icon(
            stepData['icon'] as IconData,
            color: stepData['color'] as Color,
            size: 22,
          ),
        ),
        SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stepData['title'] as String,
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                stepData['subtitle'] as String,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (stepData['color'] as Color).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Text(
            'En cours',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: stepData['color'] as Color,
            ),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getStepData() {
    switch (currentStep) {
      case 0:
        return {
          'title': 'Étape 1 — Collecte',
          'subtitle': 'Chez $personAName',
          'icon': Icons.directions_bike_outlined,
          'color': AppTheme.primaryGreen,
        };
      case 1:
        return {
          'title': 'Étape 2 — Échange',
          'subtitle': 'Chez $personBName',
          'icon': Icons.swap_horiz,
          'color': AppTheme.primaryOrange,
        };
      case 2:
        return {
          'title': 'Étape 3 — Livraison finale',
          'subtitle': 'Retour chez $personAName',
          'icon': Icons.home_outlined,
          'color': Colors.blue,
        };
      default:
        return {
          'title': 'Échange terminé',
          'subtitle': 'Livraison complétée',
          'icon': Icons.check_circle_outline,
          'color': AppTheme.successGreen,
        };
    }
  }

  List<Widget> _buildStepInstructions() {
    final instructions = _getInstructions();
    return instructions.asMap().entries.map((entry) {
      final i = entry.key;
      final instruction = entry.value;
      return Padding(
        padding: EdgeInsets.only(bottom: i < instructions.length - 1 ? 8.5 : 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 1),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                instruction,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<String> _getInstructions() {
    switch (currentStep) {
      case 0:
        return [
          'Le livreur se rend à l\'adresse de $personAName : $personAAddress',
          '$personAName donne son code de 4 chiffres au livreur.',
          'Le livreur entre le code dans l\'application pour valider la récupération de « $personAProduct ».',
        ];
      case 1:
        return [
          'Le livreur se rend à l\'adresse de $personBName : $personBAddress',
          'Le livreur remet « $personAProduct » à $personBName.',
          '$personBName donne son code de 4 chiffres pour confirmer la réception.',
          'Le livreur récupère « $personBProduct » chez $personBName.',
        ];
      case 2:
        return [
          'Le livreur retourne chez $personAName : $personAAddress',
          'Le livreur remet « $personBProduct » à $personAName.',
          '$personAName confirme la livraison dans l\'application.',
        ];
      default:
        return ['L\'échange est terminé avec succès !'];
    }
  }
}
