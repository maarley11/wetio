import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class CodeValidationWidget extends StatelessWidget {
  final int currentStep;
  final TextEditingController controller;
  final bool hasError;
  final bool isValidating;
  final VoidCallback onValidate;
  final String personAName;
  final String personBName;

  const CodeValidationWidget({
    super.key,
    required this.currentStep,
    required this.controller,
    required this.hasError,
    required this.isValidating,
    required this.onValidate,
    required this.personAName,
    required this.personBName,
  });

  String get _stepInstruction {
    switch (currentStep) {
      case 0:
        return 'Entrez le code de $personAName pour confirmer la récupération du produit.';
      case 1:
        return 'Entrez le code de $personBName pour confirmer la remise du produit de $personAName et la récupération du produit de $personBName.';
      case 2:
        return 'Entrez le code de $personAName pour confirmer la livraison finale.';
      default:
        return 'Échange terminé.';
    }
  }

  String get _stepTitle {
    switch (currentStep) {
      case 0:
        return 'Validation — Chez $personAName';
      case 1:
        return 'Validation — Chez $personBName';
      case 2:
        return 'Validation finale — Chez $personAName';
      default:
        return 'Terminé';
    }
  }

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  _stepTitle,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.5),
          Text(
            _stepInstruction,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          SizedBox(height: 17.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 10,
                    color: AppTheme.textPrimary,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '_ _ _ _',
                    hintStyle: GoogleFonts.dmSans(
                      fontSize: 24,
                      letterSpacing: 10,
                      color: AppTheme.borderLight,
                    ),
                    errorText: hasError ? 'Code incorrect. Réessayez.' : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color:
                            hasError ? AppTheme.errorRed : AppTheme.borderLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryGreen,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: AppTheme.errorRed,
                        width: 1.5,
                      ),
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundWhite,
                  ),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              SizedBox(width: 12.0),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ElevatedButton(
                  onPressed: isValidating ? null : onValidate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 15.3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 2,
                  ),
                  child: isValidating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Valider',
                          style: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
