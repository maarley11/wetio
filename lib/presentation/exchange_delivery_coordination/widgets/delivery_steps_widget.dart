import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class DeliveryStepsWidget extends StatelessWidget {
  final int currentStep;
  final String personAName;
  final String personBName;
  final String personAProduct;
  final String personBProduct;

  const DeliveryStepsWidget({
    super.key,
    required this.currentStep,
    required this.personAName,
    required this.personBName,
    required this.personAProduct,
    required this.personBProduct,
  });

  @override
  Widget build(BuildContext context) {
    final steps = [
      {
        'title': 'Étape 1 : Collecte',
        'description':
            'Le livreur se rend chez $personAName et récupère « $personAProduct »',
        'icon': Icons.directions_bike,
        'color': AppTheme.primaryGreen,
      },
      {
        'title': 'Étape 2 : Échange',
        'description':
            'Le livreur va chez $personBName, livre « $personAProduct » et récupère « $personBProduct »',
        'icon': Icons.swap_horiz,
        'color': Colors.orange,
      },
      {
        'title': 'Étape 3 : Retour',
        'description':
            'Le livreur retourne chez $personAName et livre « $personBProduct »',
        'icon': Icons.home,
        'color': Colors.blue,
      },
    ];

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
          Text(
            'Processus de livraison',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 17.0),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isCompleted = currentStep > index;
            final isActive = currentStep == index;
            final color = step['color'] as Color;

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 40.0,
                          height: 40.0,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? AppTheme.successGreen
                                : isActive
                                    ? color
                                    : AppTheme.borderLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCompleted
                                ? Icons.check
                                : step['icon'] as IconData,
                            color: isCompleted || isActive
                                ? Colors.white
                                : AppTheme.textSecondary,
                            size: 18,
                          ),
                        ),
                        if (index < steps.length - 1)
                          Container(
                            width: 2,
                            height: 34.0,
                            color: isCompleted
                                ? AppTheme.successGreen
                                : AppTheme.borderLight,
                          ),
                      ],
                    ),
                    SizedBox(width: 12.0),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          bottom: index < steps.length - 1 ? 17.0 : 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step['title'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isCompleted
                                    ? AppTheme.successGreen
                                    : isActive
                                        ? AppTheme.textPrimary
                                        : AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              step['description'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            if (isActive)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                                child: Text(
                                  'En cours',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
